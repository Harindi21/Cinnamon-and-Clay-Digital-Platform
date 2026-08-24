package dev.cinnamonandclay.cafe.media;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import javax.imageio.ImageIO;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.jayway.jsonpath.JsonPath;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.matchesPattern;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
@Import(AdminMediaApiIntegrationTest.FakeStorageConfiguration.class)
class AdminMediaApiIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres =
            new PostgreSQLContainer("postgres:18.6-alpine");

    @Autowired
    MockMvc mockMvc;

    @Autowired
    JdbcTemplate jdbcTemplate;

    @Autowired
    MediaStorage mediaStorage;

    private FakeMediaStorage storage;

    @BeforeEach
    void reset() {
        jdbcTemplate.update("DELETE FROM media_asset");
        storage = (FakeMediaStorage) mediaStorage;
        storage.clear();
    }

    @Test
    void mediaAdministrationRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/api/v1/admin/media"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(
                        multipart("/api/v1/admin/media")
                                .file(png("hero.png", 24, 16))
                                .param("purpose", "HERO")
                )
                .andExpect(status().isUnauthorized());
    }

    @Test
    void uploadRequiresTheFilePart() throws Exception {
        mockMvc.perform(
                        multipart("/api/v1/admin/media")
                                .param("purpose", "GALLERY")
                                .with(editorJwt())
                )
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.type")
                        .value("urn:cinnamon-clay:problem:malformed-request"));
    }

    @Test
    void editorCanUploadSniffedImageAndPublicApiExposesDimensions() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "..\\unsafe\\hero.png",
                "text/plain",
                pngBytes(40, 30)
        );

        MvcResult created = mockMvc.perform(
                        multipart("/api/v1/admin/media")
                                .file(file)
                                .param("purpose", "HERO")
                                .param("altText", "Cafe interior")
                                .param("caption", "Morning light in the cafe")
                                .param("focalXPercent", "35")
                                .param("focalYPercent", "60")
                                .param("sortOrder", "10")
                                .param("active", "true")
                                .with(editorJwt())
                )
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.contentType").value("image/png"))
                .andExpect(jsonPath("$.originalFilename").value("hero.png"))
                .andExpect(jsonPath("$.widthPixels").value(40))
                .andExpect(jsonPath("$.heightPixels").value(30))
                .andExpect(jsonPath("$.caption").value("Morning light in the cafe"))
                .andExpect(jsonPath("$.focalXPercent").value(35))
                .andExpect(jsonPath("$.focalYPercent").value(60))
                .andExpect(jsonPath("$.checksumSha256").value(matchesPattern("[0-9a-f]{64}")))
                .andReturn();

        String createdBody = created.getResponse().getContentAsString();
        String id = JsonPath.read(createdBody, "$.id");
        String checksum = JsonPath.read(createdBody, "$.checksumSha256");

        assertThat(storage.keys()).hasSize(1);
        assertThat(storage.keys().getFirst()).startsWith("media/hero/").endsWith(".png");

        mockMvc.perform(get("/api/v1/media"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hero.id").value(id))
                .andExpect(jsonPath("$.hero.width").value(40))
                .andExpect(jsonPath("$.hero.height").value(30))
                .andExpect(jsonPath("$.hero.caption").value("Morning light in the cafe"))
                .andExpect(jsonPath("$.hero.focalXPercent").value(35))
                .andExpect(jsonPath("$.hero.focalYPercent").value(60))
                .andExpect(jsonPath("$.hero.version").isNumber());

        mockMvc.perform(get("/api/v1/media/{id}/content", id))
                .andExpect(status().isOk())
                .andExpect(content().contentType("image/png"))
                .andExpect(header().string("X-Content-Type-Options", "nosniff"))
                .andExpect(header().string("ETag", "\"" + checksum + "\""));
    }

    @Test
    void uploadingNewActiveSingletonDeactivatesPreviousAsset() throws Exception {
        AssetVersion first = upload("first.png", "HERO", true, 10);
        AssetVersion second = upload("second.png", "HERO", true, 20);

        mockMvc.perform(get("/api/v1/admin/media").with(editorJwt()))
                .andExpect(status().isOk())
                .andExpect(jsonPath(
                        "$.assets[?(@.id == '%s')].active".formatted(first.id())
                ).value(contains(false)))
                .andExpect(jsonPath(
                        "$.assets[?(@.id == '%s')].active".formatted(second.id())
                ).value(contains(true)));

        mockMvc.perform(get("/api/v1/media"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hero.id").value(second.id()));
    }

    @Test
    void metadataWritesUseOptimisticConcurrency() throws Exception {
        AssetVersion created = upload("gallery.png", "GALLERY", true, 10);

        MvcResult updated = mockMvc.perform(
                        put("/api/v1/admin/media/{id}", created.id())
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "purpose": "GALLERY",
                                          "altText": "Updated gallery image",
                                          "sortOrder": 11,
                                          "active": true,
                                          "version": %d
                                        }
                                        """.formatted(created.version()))
                )
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.altText").value("Updated gallery image"))
                .andReturn();

        long newVersion = JsonPath.<Number>read(
                updated.getResponse().getContentAsString(),
                "$.version"
        ).longValue();
        assertThat(newVersion).isGreaterThan(created.version());

        mockMvc.perform(
                        put("/api/v1/admin/media/{id}", created.id())
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "purpose": "GALLERY",
                                          "altText": "Stale update",
                                          "sortOrder": 12,
                                          "active": true,
                                          "version": %d
                                        }
                                        """.formatted(created.version()))
                )
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.type")
                        .value("urn:cinnamon-clay:problem:conflict"));
    }

    @Test
    void legacyMetadataUpdatePreservesNewEditorialFieldsWhenTheyAreOmitted() throws Exception {
        MvcResult created = mockMvc.perform(
                        multipart("/api/v1/admin/media")
                                .file(png("gallery.png", 32, 24))
                                .param("purpose", "GALLERY")
                                .param("altText", "Original alt")
                                .param("caption", "Keep this caption")
                                .param("focalXPercent", "28")
                                .param("focalYPercent", "74")
                                .param("sortOrder", "10")
                                .param("active", "true")
                                .with(editorJwt())
                )
                .andExpect(status().isCreated())
                .andReturn();

        String body = created.getResponse().getContentAsString();
        String id = JsonPath.read(body, "$.id");
        long version = JsonPath.<Number>read(body, "$.version").longValue();

        mockMvc.perform(
                        put("/api/v1/admin/media/{id}", id)
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "purpose": "GALLERY",
                                          "altText": "Updated alt",
                                          "sortOrder": 20,
                                          "active": true,
                                          "version": %d
                                        }
                                        """.formatted(version))
                )
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.altText").value("Updated alt"))
                .andExpect(jsonPath("$.caption").value("Keep this caption"))
                .andExpect(jsonPath("$.focalXPercent").value(28))
                .andExpect(jsonPath("$.focalYPercent").value(74));
    }

    @Test
    void metadataUpdateRequiresAnExplicitVersion() throws Exception {
        AssetVersion created = upload("gallery.png", "GALLERY", true, 10);

        mockMvc.perform(
                        put("/api/v1/admin/media/{id}", created.id())
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "purpose": "GALLERY",
                                          "altText": "Missing version",
                                          "sortOrder": 11,
                                          "active": true
                                        }
                                        """)
                )
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.type")
                        .value("urn:cinnamon-clay:problem:validation"));
    }

    @Test
    void editorCanReplaceBinaryAndSupersededObjectIsRemoved() throws Exception {
        AssetVersion created = upload("before.png", "GALLERY", true, 10);
        String oldKey = storage.keys().getFirst();
        byte[] replacementBytes = pngBytes(64, 48);
        MockMultipartFile replacement = new MockMultipartFile(
                "file",
                "after.png",
                "image/png",
                replacementBytes
        );

        MvcResult result = mockMvc.perform(
                        multipart("/api/v1/admin/media/{id}/content", created.id())
                                .file(replacement)
                                .param("version", Long.toString(created.version()))
                                .with(request -> {
                                    request.setMethod("PUT");
                                    return request;
                                })
                                .with(editorJwt())
                )
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.widthPixels").value(64))
                .andExpect(jsonPath("$.heightPixels").value(48))
                .andReturn();

        long version = JsonPath.<Number>read(
                result.getResponse().getContentAsString(),
                "$.version"
        ).longValue();
        assertThat(version).isGreaterThan(created.version());
        assertThat(storage.keys()).hasSize(1);
        assertThat(storage.keys()).doesNotContain(oldKey);

        mockMvc.perform(get("/api/v1/media/{id}/content", created.id()))
                .andExpect(status().isOk())
                .andExpect(content().bytes(replacementBytes));
    }

    @Test
    void staleReplacementDeletesItsUncommittedObject() throws Exception {
        AssetVersion created = upload("before.png", "GALLERY", true, 10);
        String committedKey = storage.keys().getFirst();

        mockMvc.perform(
                        put("/api/v1/admin/media/{id}", created.id())
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "purpose": "GALLERY",
                                          "altText": "Concurrent metadata edit",
                                          "sortOrder": 10,
                                          "active": true,
                                          "version": %d
                                        }
                                        """.formatted(created.version()))
                )
                .andExpect(status().isOk());

        mockMvc.perform(
                        multipart("/api/v1/admin/media/{id}/content", created.id())
                                .file(png("stale.png", 48, 36))
                                .param("version", Long.toString(created.version()))
                                .with(request -> {
                                    request.setMethod("PUT");
                                    return request;
                                })
                                .with(editorJwt())
                )
                .andExpect(status().isConflict());

        assertThat(storage.keys()).containsExactly(committedKey);
    }

    @Test
    void editorCanAtomicallyReorderTheActiveGallery() throws Exception {
        AssetVersion first = upload("first.png", "GALLERY", true, 20);
        AssetVersion second = upload("second.png", "GALLERY", true, 10);

        mockMvc.perform(
                        put("/api/v1/admin/media/gallery/order")
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "items": [
                                            {"id": "%s", "version": %d},
                                            {"id": "%s", "version": %d}
                                          ]
                                        }
                                        """.formatted(
                                                first.id(),
                                                first.version(),
                                                second.id(),
                                                second.version()
                                        ))
                )
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.assets[0].id").value(first.id()))
                .andExpect(jsonPath("$.assets[0].sortOrder").value(10))
                .andExpect(jsonPath("$.assets[1].id").value(second.id()))
                .andExpect(jsonPath("$.assets[1].sortOrder").value(20));

        mockMvc.perform(get("/api/v1/media"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.gallery[0].id").value(first.id()))
                .andExpect(jsonPath("$.gallery[1].id").value(second.id()));

        Integer auditCount = jdbcTemplate.queryForObject(
                """
                SELECT COUNT(*)
                FROM admin_audit_event
                WHERE action = 'REORDER'
                  AND resource_type = 'media.gallery-order'
                """,
                Integer.class
        );
        assertThat(auditCount).isOne();
    }

    @Test
    void galleryReorderRejectsIncompleteAssetSet() throws Exception {
        AssetVersion first = upload("first.png", "GALLERY", true, 10);
        upload("second.png", "GALLERY", true, 20);

        mockMvc.perform(
                        put("/api/v1/admin/media/gallery/order")
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "items": [
                                            {"id": "%s", "version": %d}
                                          ]
                                        }
                                        """.formatted(first.id(), first.version()))
                )
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.type")
                        .value("urn:cinnamon-clay:problem:conflict"));
    }

    @Test
    void galleryReorderRejectsStaleVersions() throws Exception {
        AssetVersion first = upload("first.png", "GALLERY", true, 10);
        AssetVersion second = upload("second.png", "GALLERY", true, 20);

        mockMvc.perform(
                        put("/api/v1/admin/media/{id}", first.id())
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "purpose": "GALLERY",
                                          "altText": "changed",
                                          "caption": "",
                                          "focalXPercent": 50,
                                          "focalYPercent": 50,
                                          "sortOrder": 10,
                                          "active": true,
                                          "version": %d
                                        }
                                        """.formatted(first.version()))
                )
                .andExpect(status().isOk());

        mockMvc.perform(
                        put("/api/v1/admin/media/gallery/order")
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "items": [
                                            {"id": "%s", "version": %d},
                                            {"id": "%s", "version": %d}
                                          ]
                                        }
                                        """.formatted(
                                                second.id(),
                                                second.version(),
                                                first.id(),
                                                first.version()
                                        ))
                )
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.type")
                        .value("urn:cinnamon-clay:problem:conflict"));
    }

    @Test
    void focalPointPercentagesAreValidatedAtTheApiBoundary() throws Exception {
        mockMvc.perform(
                        multipart("/api/v1/admin/media")
                                .file(png("gallery.png", 32, 24))
                                .param("purpose", "GALLERY")
                                .param("focalXPercent", "101")
                                .param("focalYPercent", "50")
                                .with(editorJwt())
                )
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.type")
                        .value("urn:cinnamon-clay:problem:validation"));

        assertThat(storage.keys()).isEmpty();
    }

    @Test
    void invalidImageContentIsRejectedBeforeObjectStorageWrite() throws Exception {
        MockMultipartFile fakeImage = new MockMultipartFile(
                "file",
                "not-really.png",
                "image/png",
                "definitely not an image".getBytes(java.nio.charset.StandardCharsets.UTF_8)
        );

        mockMvc.perform(
                        multipart("/api/v1/admin/media")
                                .file(fakeImage)
                                .param("purpose", "GALLERY")
                                .with(editorJwt())
                )
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.type")
                        .value("urn:cinnamon-clay:problem:invalid-request"));

        assertThat(storage.keys()).isEmpty();
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM media_asset",
                Integer.class
        )).isZero();
    }

    @Test
    void imageDimensionsAreBoundedBeforeStorageWrite() throws Exception {
        mockMvc.perform(
                        multipart("/api/v1/admin/media")
                                .file(png("too-wide.png", 6001, 1))
                                .param("purpose", "GALLERY")
                                .with(editorJwt())
                )
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.type")
                        .value("urn:cinnamon-clay:problem:invalid-request"));

        assertThat(storage.keys()).isEmpty();
    }

    @Test
    void deactivationHidesBinaryFromPublicEndpointWithoutDeletingIt() throws Exception {
        AssetVersion created = upload("gallery.png", "GALLERY", true, 10);
        assertThat(storage.keys()).hasSize(1);

        mockMvc.perform(
                        delete("/api/v1/admin/media/{id}", created.id())
                                .param("version", Long.toString(created.version()))
                                .with(editorJwt())
                )
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/v1/media/{id}/content", created.id()))
                .andExpect(status().isNotFound());
        mockMvc.perform(
                        get("/api/v1/admin/media/{id}/content", created.id())
                                .with(editorJwt())
                )
                .andExpect(status().isOk())
                .andExpect(content().contentType("image/png"));
        assertThat(storage.keys()).hasSize(1);
    }

    @Test
    void orphanMaintenanceIsAdminOnlyAndHonorsGracePeriod() throws Exception {
        storage.putObject(
                "media/gallery/old-orphan.png",
                pngBytes(8, 8),
                Instant.now().minus(2, ChronoUnit.HOURS)
        );
        storage.putObject(
                "media/gallery/recent-inflight.png",
                pngBytes(8, 8),
                Instant.now()
        );

        mockMvc.perform(get("/api/v1/admin/media/orphans").with(editorJwt()))
                .andExpect(status().isForbidden());

        mockMvc.perform(get("/api/v1/admin/media/orphans").with(adminJwt()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.count").value(1))
                .andExpect(jsonPath("$.objectKeys[0]")
                        .value("media/gallery/old-orphan.png"));

        mockMvc.perform(delete("/api/v1/admin/media/orphans").with(adminJwt()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.discovered").value(1))
                .andExpect(jsonPath("$.deleted").value(1))
                .andExpect(jsonPath("$.failed").value(0));

        assertThat(storage.keys())
                .containsExactly("media/gallery/recent-inflight.png");
    }

    private AssetVersion upload(
            String filename,
            String purpose,
            boolean active,
            int sortOrder
    ) throws Exception {
        MvcResult result = mockMvc.perform(
                        multipart("/api/v1/admin/media")
                                .file(png(filename, 32, 24))
                                .param("purpose", purpose)
                                .param("altText", filename)
                                .param("sortOrder", Integer.toString(sortOrder))
                                .param("active", Boolean.toString(active))
                                .with(editorJwt())
                )
                .andExpect(status().isCreated())
                .andReturn();
        String body = result.getResponse().getContentAsString();
        return new AssetVersion(
                JsonPath.read(body, "$.id"),
                JsonPath.<Number>read(body, "$.version").longValue()
        );
    }

    private static MockMultipartFile png(
            String filename,
            int width,
            int height
    ) throws Exception {
        return new MockMultipartFile(
                "file",
                filename,
                "image/png",
                pngBytes(width, height)
        );
    }

    private static byte[] pngBytes(int width, int height) throws Exception {
        BufferedImage image = new BufferedImage(
                width,
                height,
                BufferedImage.TYPE_INT_RGB
        );
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        ImageIO.write(image, "png", output);
        return output.toByteArray();
    }

    private static RequestPostProcessor editorJwt() {
        return jwt().authorities(new SimpleGrantedAuthority("ROLE_EDITOR"));
    }

    private static RequestPostProcessor adminJwt() {
        return jwt().authorities(new SimpleGrantedAuthority("ROLE_ADMIN"));
    }

    private record AssetVersion(String id, long version) {
    }

    @TestConfiguration
    static class FakeStorageConfiguration {

        @Bean
        @Primary
        MediaStorage fakeMediaStorage() {
            return new FakeMediaStorage();
        }
    }

    static final class FakeMediaStorage implements MediaStorage {

        private final Map<String, StoredValue> objects = new LinkedHashMap<>();

        @Override
        public synchronized void store(
                String objectKey,
                InputStream content,
                long contentLength,
                String contentType
        ) {
            try {
                byte[] bytes = content.readAllBytes();
                if (bytes.length != contentLength) {
                    throw new IllegalStateException("Unexpected content length");
                }
                objects.put(
                        objectKey,
                        new StoredValue(bytes, contentType, Instant.now())
                );
            } catch (java.io.IOException exception) {
                throw new IllegalStateException(exception);
            }
        }

        @Override
        public synchronized InputStream open(String objectKey) {
            StoredValue value = objects.get(objectKey);
            if (value == null) {
                throw new IllegalStateException("Object not found: " + objectKey);
            }
            return new ByteArrayInputStream(value.bytes());
        }

        @Override
        public synchronized void delete(String objectKey) {
            objects.remove(objectKey);
        }

        @Override
        public synchronized List<StoredObject> list(String prefix) {
            List<StoredObject> result = new ArrayList<>();
            objects.forEach((key, value) -> {
                if (key.startsWith(prefix)) {
                    result.add(new StoredObject(
                            key,
                            value.lastModified(),
                            value.bytes().length
                    ));
                }
            });
            return List.copyOf(result);
        }

        synchronized void clear() {
            objects.clear();
        }

        synchronized List<String> keys() {
            return List.copyOf(objects.keySet());
        }

        synchronized void putObject(String key, byte[] bytes, Instant lastModified) {
            objects.put(key, new StoredValue(bytes, "image/png", lastModified));
        }

        private record StoredValue(
                byte[] bytes,
                String contentType,
                Instant lastModified
        ) {
        }
    }
}

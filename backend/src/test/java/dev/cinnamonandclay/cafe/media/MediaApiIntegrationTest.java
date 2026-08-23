package dev.cinnamonandclay.cafe.media;

import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class MediaApiIntegrationTest {

    private static final UUID HERO_ID =
            UUID.fromString("50000000-0000-0000-0000-000000000001");

    private static final UUID GALLERY_ID =
            UUID.fromString("50000000-0000-0000-0000-000000000002");

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres =
            new PostgreSQLContainer("postgres:18.6-alpine");

    @Autowired
    MockMvc mockMvc;

    @Autowired
    JdbcTemplate jdbcTemplate;

    @BeforeEach
    void seedMediaMetadata() {
        jdbcTemplate.update("DELETE FROM media_asset");

        insertMedia(
                HERO_ID,
                "hero/main.jpg",
                "hero.jpg",
                "image/jpeg",
                150_000,
                "HERO",
                "Cinnamon & Clay cafe interior",
                10,
                true
        );

        insertMedia(
                GALLERY_ID,
                "gallery/latte.jpg",
                "latte.jpg",
                "image/jpeg",
                90_000,
                "GALLERY",
                "Fresh latte on a cafe table",
                10,
                true
        );
    }

    @Test
    void returnsPublicMediaMetadata() throws Exception {
        mockMvc.perform(get("/api/v1/media"))
                .andExpect(status().isOk())
                .andExpect(
                        jsonPath("$.hero.id")
                                .value(HERO_ID.toString())
                )
                .andExpect(
                        jsonPath("$.hero.alt")
                                .value("Cinnamon & Clay cafe interior")
                )
                .andExpect(
                        jsonPath("$.gallery[0].id")
                                .value(GALLERY_ID.toString())
                )
                .andExpect(
                        jsonPath("$.gallery[0].url")
                                .value(
                                        "/api/v1/media/"
                                                + GALLERY_ID
                                                + "/content"
                                )
                );
    }

    @Test
    void returnsNotFoundForUnknownMediaContent() throws Exception {
        mockMvc.perform(
                        get(
                                "/api/v1/media/{id}/content",
                                UUID.randomUUID()
                        )
                )
                .andExpect(status().isNotFound())
                .andExpect(
                        jsonPath("$.type")
                                .value("urn:cinnamon-clay:problem:not-found")
                );
    }

    private void insertMedia(
            UUID id,
            String objectKey,
            String filename,
            String contentType,
            long sizeBytes,
            String purpose,
            String altText,
            int sortOrder,
            boolean active
    ) {
        jdbcTemplate.update(
                """
                INSERT INTO media_asset (
                    id,
                    object_key,
                    original_filename,
                    content_type,
                    size_bytes,
                    purpose,
                    alt_text,
                    sort_order,
                    active
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                id,
                objectKey,
                filename,
                contentType,
                sizeBytes,
                purpose,
                altText,
                sortOrder,
                active
        );
    }
}
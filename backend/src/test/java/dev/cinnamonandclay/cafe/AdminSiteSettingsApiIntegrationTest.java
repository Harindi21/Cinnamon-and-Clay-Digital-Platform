package dev.cinnamonandclay.cafe;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.jayway.jsonpath.JsonPath;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class AdminSiteSettingsApiIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres =
            new PostgreSQLContainer("postgres:18.6-alpine");

    @Autowired
    MockMvc mockMvc;

    @Test
    void siteSettingsRequireAuthentication() throws Exception {
        mockMvc.perform(get("/api/v1/admin/content"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/admin/contact"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void editorCanReadVersionedSiteSettings() throws Exception {
        mockMvc.perform(get("/api/v1/admin/content").with(editorJwt()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.site.brandName").isString())
                .andExpect(jsonPath("$.site.version").isNumber())
                .andExpect(jsonPath("$.paragraphs[0].version").isNumber())
                .andExpect(jsonPath("$.features[0].version").isNumber());

        mockMvc.perform(get("/api/v1/admin/contact").with(editorJwt()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profile.email").isString())
                .andExpect(jsonPath("$.profile.version").isNumber())
                .andExpect(jsonPath("$.hours[0].version").isNumber())
                .andExpect(jsonPath("$.socialLinks[0].version").isNumber());
    }

    @Test
    void editorCanUpdateSiteProfileAndStaleWriteConflicts() throws Exception {
        long version = readLong("/api/v1/admin/content", "$.site.version");

        MvcResult updated = mockMvc.perform(
                        put("/api/v1/admin/content/site")
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(siteUpdateJson(
                                        "Cinnamon & Clay Studio",
                                        version
                                ))
                )
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.brandName").value("Cinnamon & Clay Studio"))
                .andReturn();

        Number newVersion = JsonPath.read(
                updated.getResponse().getContentAsString(),
                "$.version"
        );

        mockMvc.perform(get("/api/v1/content/site"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.brand.name").value("Cinnamon & Clay Studio"));

        mockMvc.perform(
                        put("/api/v1/admin/content/site")
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(siteUpdateJson("Stale name", version))
                )
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.type")
                        .value("urn:cinnamon-clay:problem:conflict"));

        mockMvc.perform(
                        put("/api/v1/admin/content/site")
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(siteUpdateJson(
                                        "Cinnamon & Clay",
                                        newVersion.longValue()
                                ))
                )
                .andExpect(status().isOk());
    }

    @Test
    void editorCanManageAboutParagraphsAndFeatures() throws Exception {
        MutationData paragraph = create(
                "/api/v1/admin/content/paragraphs",
                """
                        {
                          "body": "A temporary portfolio test paragraph.",
                          "sortOrder": 900,
                          "active": true
                        }
                        """
        );

        MvcResult updatedParagraph = mockMvc.perform(
                        put("/api/v1/admin/content/paragraphs/{id}", paragraph.id())
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "body": "Updated portfolio test paragraph.",
                                          "sortOrder": 901,
                                          "active": true,
                                          "version": %d
                                        }
                                        """.formatted(paragraph.version()))
                )
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.body")
                        .value("Updated portfolio test paragraph."))
                .andReturn();
        long paragraphVersion = JsonPath.<Number>read(
                updatedParagraph.getResponse().getContentAsString(),
                "$.version"
        ).longValue();

        mockMvc.perform(
                        delete("/api/v1/admin/content/paragraphs/{id}", paragraph.id())
                                .with(editorJwt())
                                .param("version", Long.toString(paragraphVersion))
                )
                .andExpect(status().isNoContent());

        MutationData feature = create(
                "/api/v1/admin/content/features",
                """
                        {
                          "icon": "☕",
                          "title": "Test feature",
                          "text": "Used to verify admin feature management.",
                          "sortOrder": 900,
                          "active": true
                        }
                        """
        );

        mockMvc.perform(
                        delete("/api/v1/admin/content/features/{id}", feature.id())
                                .with(editorJwt())
                                .param("version", Long.toString(feature.version()))
                )
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/v1/admin/content").with(editorJwt()))
                .andExpect(status().isOk())
                .andExpect(jsonPath(
                        "$.paragraphs[?(@.id == '%s' && @.active == false)]".formatted(paragraph.id())
                ).isNotEmpty())
                .andExpect(jsonPath(
                        "$.features[?(@.id == '%s' && @.active == false)]".formatted(feature.id())
                ).isNotEmpty());
    }

    @Test
    void editorCanUpdateContactProfileAndStaleWriteConflicts() throws Exception {
        long version = readLong("/api/v1/admin/contact", "$.profile.version");

        MvcResult updated = mockMvc.perform(
                        put("/api/v1/admin/contact/profile")
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(contactUpdateJson(
                                        "portfolio-test@cinnamonandclay.lk",
                                        version
                                ))
                )
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email")
                        .value("portfolio-test@cinnamonandclay.lk"))
                .andReturn();

        long newVersion = JsonPath.<Number>read(
                updated.getResponse().getContentAsString(),
                "$.version"
        ).longValue();

        mockMvc.perform(get("/api/v1/contact"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email")
                        .value("portfolio-test@cinnamonandclay.lk"));

        mockMvc.perform(
                        put("/api/v1/admin/contact/profile")
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(contactUpdateJson("stale@example.com", version))
                )
                .andExpect(status().isConflict());

        mockMvc.perform(
                        put("/api/v1/admin/contact/profile")
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(contactUpdateJson(
                                        "hello@cinnamonandclay.lk",
                                        newVersion
                                ))
                )
                .andExpect(status().isOk());
    }

    @Test
    void editorCanManageOpeningHoursAndSocialLinks() throws Exception {
        MutationData hour = create(
                "/api/v1/admin/contact/hours",
                """
                        {
                          "dayLabel": "Poya holiday",
                          "timeLabel": "9.00 am – 3.00 pm",
                          "sortOrder": 900,
                          "active": true
                        }
                        """
        );

        mockMvc.perform(
                        delete("/api/v1/admin/contact/hours/{id}", hour.id())
                                .with(editorJwt())
                                .param("version", Long.toString(hour.version()))
                )
                .andExpect(status().isNoContent());

        MutationData link = create(
                "/api/v1/admin/contact/social-links",
                """
                        {
                          "platform": "youtube-demo",
                          "url": "https://example.com/cinnamon-clay-video",
                          "sortOrder": 900,
                          "active": true
                        }
                        """
        );

        MvcResult updatedLink = mockMvc.perform(
                        put("/api/v1/admin/contact/social-links/{id}", link.id())
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "platform": "youtube-demo",
                                          "url": "https://example.com/cinnamon-clay-demo",
                                          "sortOrder": 901,
                                          "active": true,
                                          "version": %d
                                        }
                                        """.formatted(link.version()))
                )
                .andExpect(status().isOk())
                .andReturn();
        long linkVersion = JsonPath.<Number>read(
                updatedLink.getResponse().getContentAsString(),
                "$.version"
        ).longValue();

        mockMvc.perform(
                        delete("/api/v1/admin/contact/social-links/{id}", link.id())
                                .with(editorJwt())
                                .param("version", Long.toString(linkVersion))
                )
                .andExpect(status().isNoContent());
    }

    @Test
    void updateRequiresAnExplicitOptimisticConcurrencyVersion() throws Exception {
        mockMvc.perform(
                        put("/api/v1/admin/content/site")
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "brandName": "Cinnamon & Clay",
                                          "tagline": "Slow coffee. Warm bakes. Good company.",
                                          "heroNote": "Colombo",
                                          "menuNote": "Prices in LKR",
                                          "aboutTitle": "Our little story"
                                        }
                                        """)
                )
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.type")
                        .value("urn:cinnamon-clay:problem:validation"));
    }

    @Test
    void invalidAdminManagedUrlsAndWhatsappNumbersAreRejected() throws Exception {
        long version = readLong("/api/v1/admin/contact", "$.profile.version");

        mockMvc.perform(
                        put("/api/v1/admin/contact/profile")
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "address": "42 Flower Road, Colombo 07, Sri Lanka",
                                          "phone": "+94 77 123 4567",
                                          "email": "hello@cinnamonandclay.lk",
                                          "mapEmbedUrl": "http://insecure.example.com/map",
                                          "whatsappEnabled": true,
                                          "whatsappNumber": "0771234567",
                                          "whatsappPrefill": "Hello",
                                          "version": %d
                                        }
                                        """.formatted(version))
                )
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.type")
                        .value("urn:cinnamon-clay:problem:validation"));
    }

    private MutationData create(String path, String body) throws Exception {
        MvcResult result = mockMvc.perform(
                        post(path)
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body)
                )
                .andExpect(status().isCreated())
                .andReturn();
        String response = result.getResponse().getContentAsString();
        return new MutationData(
                JsonPath.read(response, "$.id"),
                JsonPath.<Number>read(response, "$.version").longValue()
        );
    }

    private long readLong(String path, String jsonPath) throws Exception {
        MvcResult result = mockMvc.perform(get(path).with(editorJwt()))
                .andExpect(status().isOk())
                .andReturn();
        return JsonPath.<Number>read(
                result.getResponse().getContentAsString(),
                jsonPath
        ).longValue();
    }

    private static String siteUpdateJson(String brandName, long version) {
        return """
                {
                  "brandName": "%s",
                  "tagline": "Slow coffee. Warm bakes. Good company.",
                  "heroNote": "A neighbourhood coffee house in the heart of Colombo.",
                  "menuNote": "Prices in Sri Lankan Rupees. Ask us about today's specials!",
                  "aboutTitle": "Our little story",
                  "version": %d
                }
                """.formatted(brandName, version);
    }

    private static String contactUpdateJson(String email, long version) {
        return """
                {
                  "address": "42 Flower Road, Colombo 07, Sri Lanka",
                  "phone": "+94 77 123 4567",
                  "email": "%s",
                  "mapEmbedUrl": "https://www.google.com/maps?q=Colombo+07,+Sri+Lanka&output=embed",
                  "whatsappEnabled": true,
                  "whatsappNumber": "+94771234567",
                  "whatsappPrefill": "Hi! I'd like to place an order 🙂",
                  "version": %d
                }
                """.formatted(email, version);
    }

    private static RequestPostProcessor editorJwt() {
        return jwt().authorities(new SimpleGrantedAuthority("ROLE_EDITOR"));
    }

    private record MutationData(String id, long version) {
    }
}

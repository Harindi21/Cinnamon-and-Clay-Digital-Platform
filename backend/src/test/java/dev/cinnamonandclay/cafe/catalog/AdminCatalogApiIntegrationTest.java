package dev.cinnamonandclay.cafe.catalog;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
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
class AdminCatalogApiIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:18.6-alpine");

    @Autowired
    MockMvc mockMvc;

    @Test
    void adminCatalogRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/api/v1/admin/catalog"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void editorCanReadInactiveAndVersionedCatalog() throws Exception {
        mockMvc.perform(
                        get("/api/v1/admin/catalog")
                                .with(editorJwt())
                )
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.defaultCurrency").value("LKR"))
                .andExpect(jsonPath("$.categories[0].slug").value("coffee"))
                .andExpect(jsonPath("$.categories[0].active").value(true))
                .andExpect(jsonPath("$.categories[0].version").isNumber())
                .andExpect(jsonPath("$.categories[0].items[0].version").isNumber());
    }

    @Test
    void editorCanCreateUpdateAndDeactivateCategory() throws Exception {
        ResponseData created = performJson(
                post("/api/v1/admin/catalog/categories")
                        .with(editorJwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "slug": "seasonal-specials",
                                  "name": "Seasonal Specials",
                                  "sortOrder": 55,
                                  "active": true
                                }
                                """),
                201
        );

        UUID id = UUID.fromString(created.id());
        long version = created.version();

        ResponseData updated = performJson(
                put("/api/v1/admin/catalog/categories/{id}", id)
                        .with(editorJwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "slug": "seasonal",
                                  "name": "Seasonal",
                                  "sortOrder": 56,
                                  "active": true,
                                  "version": %d
                                }
                                """.formatted(version)),
                200
        );

        long updatedVersion = updated.version();

        mockMvc.perform(
                        delete("/api/v1/admin/catalog/categories/{id}", id)
                                .param("version", Long.toString(updatedVersion))
                                .with(editorJwt())
                )
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/v1/catalog/menu"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.categories[?(@.id == '%s')]".formatted(id)).isEmpty());
    }

    @Test
    void staleCategoryVersionReturnsConflict() throws Exception {
        ResponseData created = performJson(
                post("/api/v1/admin/catalog/categories")
                        .with(editorJwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "slug": "brunch",
                                  "name": "Brunch",
                                  "sortOrder": 60,
                                  "active": true
                                }
                                """),
                201
        );

        String id = created.id();
        long version = created.version();

        mockMvc.perform(
                        put("/api/v1/admin/catalog/categories/{id}", id)
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "slug": "brunch",
                                          "name": "Weekend Brunch",
                                          "sortOrder": 60,
                                          "active": true,
                                          "version": %d
                                        }
                                        """.formatted(version))
                )
                .andExpect(status().isOk());

        mockMvc.perform(
                        put("/api/v1/admin/catalog/categories/{id}", id)
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "slug": "brunch",
                                          "name": "Stale edit",
                                          "sortOrder": 60,
                                          "active": true,
                                          "version": %d
                                        }
                                        """.formatted(version))
                )
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.type").value("urn:cinnamon-clay:problem:conflict"));
    }

    @Test
    void editorCanCreateMoveUpdateAndDeactivateItem() throws Exception {
        ResponseData sourceCategory = createCategory("lunch", "Lunch", 70);
        ResponseData targetCategory = createCategory("late-lunch", "Late Lunch", 80);

        String sourceCategoryId = sourceCategory.id();
        String targetCategoryId = targetCategory.id();

        ResponseData created = performJson(
                post("/api/v1/admin/catalog/categories/{id}/items", sourceCategoryId)
                        .with(editorJwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Soup of the day",
                                  "description": "Ask the team for today's soup",
                                  "priceMinor": 95000,
                                  "currency": "LKR",
                                  "sortOrder": 10,
                                  "active": true
                                }
                                """),
                201
        );

        String itemId = created.id();
        long version = created.version();

        ResponseData updated = performJson(
                put("/api/v1/admin/catalog/items/{id}", itemId)
                        .with(editorJwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "categoryId": "%s",
                                  "name": "Daily soup",
                                  "description": "Made fresh each morning",
                                  "priceMinor": 99000,
                                  "currency": "LKR",
                                  "sortOrder": 15,
                                  "active": true,
                                  "version": %d
                                }
                                """.formatted(targetCategoryId, version)),
                200
        );

        mockMvc.perform(
                        delete("/api/v1/admin/catalog/items/{id}", itemId)
                                .param("version", Long.toString(updated.version()))
                                .with(editorJwt())
                )
                .andExpect(status().isNoContent());
    }

    @Test
    void invalidCategoryIsRejectedBeforePersistence() throws Exception {
        mockMvc.perform(
                        post("/api/v1/admin/catalog/categories")
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "slug": "Not Valid!",
                                          "name": "",
                                          "sortOrder": -1,
                                          "active": true
                                        }
                                        """)
                )
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.type").value("urn:cinnamon-clay:problem:validation"))
                .andExpect(jsonPath("$.errors").isArray());
    }

    private ResponseData createCategory(String slug, String name, int sortOrder) throws Exception {
        return performJson(
                post("/api/v1/admin/catalog/categories")
                        .with(editorJwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "slug": "%s",
                                  "name": "%s",
                                  "sortOrder": %d,
                                  "active": true
                                }
                                """.formatted(slug, name, sortOrder)),
                201
        );
    }

    private ResponseData performJson(
            org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder request,
            int expectedStatus
    ) throws Exception {
        MvcResult result = mockMvc.perform(request)
                .andExpect(status().is(expectedStatus))
                .andReturn();
        String body = result.getResponse().getContentAsString();
        String id = JsonPath.read(body, "$.id");
        Number version = JsonPath.read(body, "$.version");
        return new ResponseData(id, version.longValue());
    }

    private record ResponseData(String id, long version) {
    }

    private static org.springframework.test.web.servlet.request.RequestPostProcessor editorJwt() {
        return jwt().authorities(new SimpleGrantedAuthority("ROLE_EDITOR"));
    }
}

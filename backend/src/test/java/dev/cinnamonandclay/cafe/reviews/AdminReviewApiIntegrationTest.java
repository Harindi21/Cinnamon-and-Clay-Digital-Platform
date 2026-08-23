package dev.cinnamonandclay.cafe.reviews;

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
class AdminReviewApiIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:18.6-alpine");

    @Autowired
    MockMvc mockMvc;

    @Test
    void reviewAdministrationRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/api/v1/admin/reviews"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void editorCanCreatePublishAndHideReview() throws Exception {
        ResponseData created = performJson(
                post("/api/v1/admin/reviews")
                        .with(editorJwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "authorName": "Test Guest",
                                  "body": "Draft review",
                                  "rating": 5,
                                  "status": "DRAFT",
                                  "sortOrder": 90
                                }
                                """),
                201
        );

        String id = created.id();
        long version = created.version();

        ResponseData published = performJson(
                put("/api/v1/admin/reviews/{id}", id)
                        .with(editorJwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "authorName": "Test Guest",
                                  "body": "Published review",
                                  "rating": 5,
                                  "status": "PUBLISHED",
                                  "sortOrder": 90,
                                  "version": %d
                                }
                                """.formatted(version)),
                200
        );

        mockMvc.perform(get("/api/v1/reviews"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reviews[?(@.id == '%s')]".formatted(id)).isNotEmpty());

        mockMvc.perform(
                        delete("/api/v1/admin/reviews/{id}", id)
                                .param("version", Long.toString(published.version()))
                                .with(editorJwt())
                )
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/v1/reviews"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reviews[?(@.id == '%s')]".formatted(id)).isEmpty());
    }

    @Test
    void staleReviewEditReturnsConflict() throws Exception {
        ResponseData created = performJson(
                post("/api/v1/admin/reviews")
                        .with(editorJwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "authorName": "Concurrency Guest",
                                  "body": "Original",
                                  "rating": 4,
                                  "status": "DRAFT",
                                  "sortOrder": 95
                                }
                                """),
                201
        );

        String id = created.id();
        long version = created.version();
        String update = """
                {
                  "authorName": "Concurrency Guest",
                  "body": "%s",
                  "rating": 4,
                  "status": "DRAFT",
                  "sortOrder": 95,
                  "version": %d
                }
                """;

        mockMvc.perform(
                        put("/api/v1/admin/reviews/{id}", id)
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(update.formatted("First save", version))
                )
                .andExpect(status().isOk());

        mockMvc.perform(
                        put("/api/v1/admin/reviews/{id}", id)
                                .with(editorJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(update.formatted("Stale save", version))
                )
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.type").value("urn:cinnamon-clay:problem:conflict"));
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

package dev.cinnamonandclay.cafe;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class PublicSiteApiIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres =
            new PostgreSQLContainer("postgres:18.6-alpine");

    @Autowired
    MockMvc mockMvc;

    @Test
    void returnsPublicSiteContent() throws Exception {
        mockMvc.perform(get("/api/v1/content/site"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.brand.name").value("Cinnamon & Clay"))
                .andExpect(
                        jsonPath("$.brand.tagline")
                                .value("Slow coffee. Warm bakes. Good company.")
                )
                .andExpect(jsonPath("$.about.features[0].title")
                        .value("Locally roasted"));
    }

    @Test
    void returnsPublicContactInformation() throws Exception {
        mockMvc.perform(get("/api/v1/contact"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("hello@cinnamonandclay.lk"))
                .andExpect(jsonPath("$.hours[0].day")
                        .value("Monday – Friday"))
                .andExpect(jsonPath("$.socialLinks[0].platform")
                        .value("instagram"));
    }

    @Test
    void publishesOpenApiDocument() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(
                        containsString("/api/v1/catalog/menu")
                ))
                .andExpect(content().string(
                        containsString("/api/v1/content/site")
                ))
                .andExpect(content().string(
                        containsString("/api/v1/contact")
                ));
    }
}
package dev.cinnamonandclay.cafe.catalog;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class CatalogApiIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:18.6-alpine");

    @Autowired
    MockMvc mockMvc;

    @Test
    void returnsSeededPublicMenu() throws Exception {
        mockMvc.perform(get("/api/v1/catalog/menu"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.defaultCurrency").value("LKR"))
                .andExpect(jsonPath("$.categories[0].name").value("Coffee"))
                .andExpect(jsonPath("$.categories[0].items[0].name").value("Espresso"))
                .andExpect(jsonPath("$.categories[0].items[0].price.amountMinor").value(55000));
    }
}

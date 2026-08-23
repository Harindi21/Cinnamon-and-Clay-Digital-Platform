package dev.cinnamonandclay.cafe.reviews;

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
import org.testcontainers.junit
        .jupiter.Container;
import org.testcontainers.junit
        .jupiter.Testcontainers;
import org.testcontainers
        .postgresql.PostgreSQLContainer;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class ReviewApiIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres =
            new PostgreSQLContainer(
                    "postgres:18.6-alpine"
            );

    @Autowired
    MockMvc mockMvc;

    @Autowired
    JdbcTemplate jdbcTemplate;

    @Test
    void returnsOnlyPublishedReviewsInEditorialOrder()
            throws Exception {

        jdbcTemplate.update(
                """
                INSERT INTO review (
                    id,
                    author_name,
                    body,
                    rating,
                    status,
                    sort_order
                )
                VALUES (
                    ?::uuid,
                    ?,
                    ?,
                    ?,
                    ?,
                    ?
                )
                """,
                "60000000-0000-0000-0000-000000000099",
                "Internal Draft",
                "This review must not be public.",
                5,
                "DRAFT",
                1
        );

        mockMvc.perform(
                        get("/api/v1/reviews")
                )
                .andExpect(
                        status().isOk()
                )
                .andExpect(
                        jsonPath(
                                "$.reviews.length()"
                        ).value(3)
                )
                .andExpect(
                        jsonPath(
                                "$.reviews[0].authorName"
                        ).value("Dinithi P.")
                )
                .andExpect(
                        jsonPath(
                                "$.reviews[0].rating"
                        ).value(5)
                )
                .andExpect(
                        jsonPath(
                                "$.reviews[1].authorName"
                        ).value("Ashan W.")
                )
                .andExpect(
                        jsonPath(
                                "$.reviews[2].authorName"
                        ).value("Sarah F.")
                );
    }
}
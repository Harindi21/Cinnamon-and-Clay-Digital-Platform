package dev.cinnamonandclay.cafe.audit;

import java.util.Map;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.dao.DataAccessException;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.jayway.jsonpath.JsonPath;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class AdminAuditApiIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres =
            new PostgreSQLContainer("postgres:18.6-alpine");

    @Autowired
    MockMvc mockMvc;

    @Autowired
    JdbcTemplate jdbcTemplate;

    @Autowired
    AuditTrail auditTrail;

    @Autowired
    PlatformTransactionManager transactionManager;

    @Autowired
    MeterRegistry meterRegistry;

    @Test
    void auditReadRequiresAdministratorRole() throws Exception {
        mockMvc.perform(get("/api/v1/admin/audit"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(get("/api/v1/admin/audit").with(editorJwt()))
                .andExpect(status().isForbidden());

        mockMvc.perform(get("/api/v1/admin/audit").with(adminJwt()))
                .andExpect(status().isOk());
    }

    @Test
    void successfulAdminMutationCreatesCorrelatedAuditEvent() throws Exception {
        String slug = "audit-" + UUID.randomUUID();
        String requestId = "audit-request-1234";

        MvcResult created = mockMvc.perform(
                        post("/api/v1/admin/catalog/categories")
                                .header("X-Request-Id", requestId)
                                .with(adminJwt())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "slug": "%s",
                                          "name": "Audit test",
                                          "sortOrder": 999,
                                          "active": true
                                        }
                                        """.formatted(slug))
                )
                .andExpect(status().isCreated())
                .andExpect(header().string("X-Request-Id", requestId))
                .andReturn();

        String resourceId = JsonPath.read(
                created.getResponse().getContentAsString(),
                "$.id"
        );

        mockMvc.perform(
                        get("/api/v1/admin/audit")
                                .with(adminJwt())
                                .param("requestId", requestId)
                )
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(1))
                .andExpect(jsonPath("$.items[0].action").value("CREATE"))
                .andExpect(jsonPath("$.items[0].resourceType")
                        .value("catalog.category"))
                .andExpect(jsonPath("$.items[0].resourceId").value(resourceId))
                .andExpect(jsonPath("$.items[0].actorSubject")
                        .value("audit-admin-subject"))
                .andExpect(jsonPath("$.items[0].actorUsername")
                        .value("audit.admin"))
                .andExpect(jsonPath("$.items[0].actorRoles[0]").value("admin"))
                .andExpect(jsonPath("$.items[0].requestId").value(requestId))
                .andExpect(jsonPath("$.items[0].beforeState").doesNotExist())
                .andExpect(jsonPath("$.items[0].afterState.slug").value(slug));
    }

    @Test
    void auditFeedUsesBoundedCursorPagination() throws Exception {
        for (int index = 0; index < 3; index++) {
            mockMvc.perform(
                            post("/api/v1/admin/catalog/categories")
                                    .with(paginationAdminJwt())
                                    .contentType(MediaType.APPLICATION_JSON)
                                    .content("""
                                            {
                                              "slug": "audit-page-%s",
                                              "name": "Audit page %d",
                                              "sortOrder": %d,
                                              "active": true
                                            }
                                            """.formatted(
                                            UUID.randomUUID(),
                                            index,
                                            950 + index
                                    ))
                    )
                    .andExpect(status().isCreated());
        }

        MvcResult firstPage = mockMvc.perform(
                        get("/api/v1/admin/audit")
                                .with(adminJwt())
                                .param("actor", "audit.pager")
                                .param("resourceType", "catalog.category")
                                .param("limit", "2")
                )
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(2))
                .andExpect(jsonPath("$.nextCursor").isString())
                .andReturn();

        String cursor = JsonPath.read(
                firstPage.getResponse().getContentAsString(),
                "$.nextCursor"
        );

        mockMvc.perform(
                        get("/api/v1/admin/audit")
                                .with(adminJwt())
                                .param("actor", "audit.pager")
                                .param("resourceType", "catalog.category")
                                .param("limit", "2")
                                .param("cursor", cursor)
                )
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(1));
    }

    @Test
    void invalidCursorReturnsProblemDetailsWithRequestId() throws Exception {
        mockMvc.perform(
                        get("/api/v1/admin/audit")
                                .with(adminJwt())
                                .header("X-Request-Id", "audit-invalid-123")
                                .param("cursor", "not-a-cursor")
                )
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.type")
                        .value("urn:cinnamon-clay:problem:invalid-request"))
                .andExpect(jsonPath("$.requestId").value("audit-invalid-123"));
    }

    @Test
    void auditSanitizesSensitiveFieldsBeforePersistence() {
        UUID resourceId = UUID.randomUUID();

        auditTrail.record(
                AuditAction.CREATE,
                "test.sanitization",
                resourceId,
                null,
                Map.of(
                        "safe", "visible",
                        "password", "must-not-be-stored",
                        "nested", Map.of("accessToken", "must-not-be-stored")
                )
        );

        String stored = jdbcTemplate.queryForObject(
                """
                SELECT after_state::text
                FROM admin_audit_event
                WHERE resource_type = 'test.sanitization' AND resource_id = ?
                """,
                String.class,
                resourceId.toString()
        );

        assertThat(stored)
                .contains("visible")
                .contains("[REDACTED]")
                .doesNotContain("must-not-be-stored");
    }

    @Test
    void auditRecordRollsBackWithOwningTransaction() {
        UUID resourceId = UUID.randomUUID();
        TransactionTemplate transaction = new TransactionTemplate(transactionManager);
        Counter counter = meterRegistry.counter(
                "cafe.admin.audit.events",
                "action", "update",
                "resource_type", "test.rollback"
        );
        double metricBefore = counter.count();

        assertThatThrownBy(() -> transaction.executeWithoutResult(status -> {
            auditTrail.record(
                    AuditAction.UPDATE,
                    "test.rollback",
                    resourceId,
                    Map.of("value", "before"),
                    Map.of("value", "after")
            );
            throw new IllegalStateException("force rollback");
        })).isInstanceOf(IllegalStateException.class);

        Integer count = jdbcTemplate.queryForObject(
                """
                SELECT count(*)
                FROM admin_audit_event
                WHERE resource_type = 'test.rollback' AND resource_id = ?
                """,
                Integer.class,
                resourceId.toString()
        );
        assertThat(count).isZero();
        assertThat(counter.count()).isEqualTo(metricBefore);
    }

    @Test
    void databaseRejectsAuditMutationAndDeletion() {
        UUID id = UUID.randomUUID();
        jdbcTemplate.update(
                """
                INSERT INTO admin_audit_event (
                    id, actor_subject, actor_username, action, resource_type
                ) VALUES (?, 'system', 'system', 'CREATE', 'test.resource')
                """,
                id
        );

        assertThatThrownBy(() -> jdbcTemplate.update(
                "UPDATE admin_audit_event SET action = 'UPDATE' WHERE id = ?",
                id
        )).isInstanceOf(DataAccessException.class);

        assertThatThrownBy(() -> jdbcTemplate.update(
                "DELETE FROM admin_audit_event WHERE id = ?",
                id
        )).isInstanceOf(DataAccessException.class);

        assertThatThrownBy(() -> jdbcTemplate.execute(
                "TRUNCATE TABLE admin_audit_event"
        )).isInstanceOf(DataAccessException.class);
    }

    private static RequestPostProcessor editorJwt() {
        return jwt().authorities(new SimpleGrantedAuthority("ROLE_EDITOR"));
    }

    private static RequestPostProcessor paginationAdminJwt() {
        return jwt()
                .jwt(jwt -> jwt
                        .subject("audit-pager-subject")
                        .claim("preferred_username", "audit.pager"))
                .authorities(new SimpleGrantedAuthority("ROLE_ADMIN"));
    }

    private static RequestPostProcessor adminJwt() {
        return jwt()
                .jwt(jwt -> jwt
                        .subject("audit-admin-subject")
                        .claim("preferred_username", "audit.admin")
                        .claim("email", "audit.admin@example.invalid"))
                .authorities(new SimpleGrantedAuthority("ROLE_ADMIN"));
    }
}

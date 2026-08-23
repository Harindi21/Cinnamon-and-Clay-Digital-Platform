package dev.cinnamonandclay.cafe.identity;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;

import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

import static org.springframework.security.test.web.servlet.request
        .SecurityMockMvcRequestPostProcessors.jwt;

import static org.springframework.test.web.servlet.request
        .MockMvcRequestBuilders.get;

import static org.springframework.test.web.servlet.result
        .MockMvcResultMatchers.jsonPath;

import static org.springframework.test.web.servlet.result
        .MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class AdminSecurityIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres =
            new PostgreSQLContainer(
                    "postgres:18.6-alpine"
            );

    @Autowired
    MockMvc mockMvc;

    @Test
    void publicCatalogRemainsAnonymous()
            throws Exception {

        mockMvc.perform(
                        get(
                                "/api/v1/catalog/menu"
                        )
                )
                .andExpect(
                        status().isOk()
                );
    }

    @Test
    void adminEndpointRequiresAuthentication()
            throws Exception {

        mockMvc.perform(
                        get(
                                "/api/v1/admin/me"
                        )
                )
                .andExpect(
                        status().isUnauthorized()
                );
    }

    @Test
    void authenticatedUserWithoutAdminRoleIsForbidden()
            throws Exception {

        mockMvc.perform(
                        get(
                                "/api/v1/admin/me"
                        )
                                .with(
                                        jwt().jwt(
                                                token ->
                                                        token
                                                                .subject(
                                                                        "user-1"
                                                                )
                                                                .claim(
                                                                        "preferred_username",
                                                                        "ordinary.user"
                                                                )
                                        )
                                )
                )
                .andExpect(
                        status().isForbidden()
                );
    }

    @Test
    void editorCanAccessAdminIdentity()
            throws Exception {

        mockMvc.perform(
                        get(
                                "/api/v1/admin/me"
                        )
                                .with(
                                        jwt()
                                                .jwt(
                                                        token ->
                                                                token
                                                                        .subject(
                                                                                "editor-1"
                                                                        )
                                                                        .claim(
                                                                                "preferred_username",
                                                                                "local.editor"
                                                                        )
                                                                        .claim(
                                                                                "email",
                                                                                "local.editor@cinnamonandclay.test"
                                                                        )
                                                )
                                                .authorities(
                                                        new SimpleGrantedAuthority(
                                                                "ROLE_EDITOR"
                                                        )
                                                )
                                )
                )
                .andExpect(
                        status().isOk()
                )
                .andExpect(
                        jsonPath(
                                "$.username"
                        )
                                .value(
                                        "local.editor"
                                )
                )
                .andExpect(
                        jsonPath(
                                "$.roles[0]"
                        )
                                .value(
                                        "editor"
                                )
                );
    }

    @Test
    void adminCanAccessAdminIdentity()
            throws Exception {

        mockMvc.perform(
                        get(
                                "/api/v1/admin/me"
                        )
                                .with(
                                        jwt()
                                                .jwt(
                                                        token ->
                                                                token
                                                                        .subject(
                                                                                "admin-1"
                                                                        )
                                                                        .claim(
                                                                                "preferred_username",
                                                                                "local.admin"
                                                                        )
                                                                        .claim(
                                                                                "email",
                                                                                "local.admin@cinnamonandclay.test"
                                                                        )
                                                )
                                                .authorities(
                                                        new SimpleGrantedAuthority(
                                                                "ROLE_ADMIN"
                                                        )
                                                )
                                )
                )
                .andExpect(
                        status().isOk()
                )
                .andExpect(
                        jsonPath(
                                "$.subject"
                        )
                                .value(
                                        "admin-1"
                                )
                )
                .andExpect(
                        jsonPath(
                                "$.roles[0]"
                        )
                                .value(
                                        "admin"
                                )
                );
    }
}
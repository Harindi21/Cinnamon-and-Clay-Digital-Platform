package dev.kirikopi.cafe.identity;

import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

import static org.assertj.core.api.Assertions
        .assertThat;

class KeycloakClientRoleConverterTest {

    private final KeycloakClientRoleConverter
            converter =
            new KeycloakClientRoleConverter(
                    "kirikopi-api"
            );

    @Test
    void mapsOnlyRolesForKirikopiApi() {

        Jwt jwt = Jwt
                .withTokenValue("test-token")
                .header("alg", "RS256")
                .subject("admin-subject")
                .claim(
                        "resource_access",
                        Map.of(
                                "kirikopi-api",
                                Map.of(
                                        "roles",
                                        List.of(
                                                "editor",
                                                "admin"
                                        )
                                ),
                                "unrelated-client",
                                Map.of(
                                        "roles",
                                        List.of(
                                                "ignored"
                                        )
                                )
                        )
                )
                .build();

        assertThat(
                converter.convert(jwt)
        )
                .extracting(
                        GrantedAuthority
                                ::getAuthority
                )
                .containsExactlyInAnyOrder(
                        "ROLE_EDITOR",
                        "ROLE_ADMIN"
                );
    }

    @Test
    void returnsNoRolesWhenClientClaimIsMissing() {

        Jwt jwt = Jwt
                .withTokenValue("test-token")
                .header("alg", "RS256")
                .subject("admin-subject")
                .build();

        assertThat(
                converter.convert(jwt)
        ).isEmpty();
    }
}
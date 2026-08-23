package dev.kirikopi.cafe.identity;

import java.util.Collection;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

@Component
class KeycloakClientRoleConverter
        implements Converter<
                Jwt,
                Collection<GrantedAuthority>
        > {

    private final String resourceClientId;

    KeycloakClientRoleConverter(
            @Value(
                    "${app.security.oidc.resource-client-id}"
            )
            String resourceClientId
    ) {
        this.resourceClientId = resourceClientId;
    }

    @Override
    public Collection<GrantedAuthority> convert(
            Jwt jwt
    ) {
        Object resourceAccessClaim =
                jwt.getClaims().get(
                        "resource_access"
                );

        if (!(resourceAccessClaim
                instanceof Map<?, ?> resourceAccess)) {
            return List.of();
        }

        Object clientClaim =
                resourceAccess.get(
                        resourceClientId
                );

        if (!(clientClaim
                instanceof Map<?, ?> clientAccess)) {
            return List.of();
        }

        Object rolesClaim =
                clientAccess.get("roles");

        if (!(rolesClaim
                instanceof Collection<?> roles)) {
            return List.of();
        }

        return roles.stream()
                .filter(String.class::isInstance)
                .map(String.class::cast)
                .map(String::trim)
                .filter(role -> !role.isBlank())
                .map(role ->
                        role.toUpperCase(Locale.ROOT)
                                .replace('-', '_')
                )
                .distinct()
                .map(role ->
                        (GrantedAuthority)
                                new SimpleGrantedAuthority(
                                        "ROLE_" + role
                                )
                )
                .toList();
    }
}
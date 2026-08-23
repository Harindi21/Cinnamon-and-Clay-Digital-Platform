package dev.cinnamonandclay.cafe.identity;

import java.util.Collection;
import java.util.LinkedHashSet;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;

@Configuration(proxyBeanMethods = false)
@EnableWebSecurity
class SecurityConfiguration {

    @Bean
    SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            JwtAuthenticationConverter
                    jwtAuthenticationConverter
    ) throws Exception {

        http
                .csrf(
                        csrf -> csrf.ignoringRequestMatchers(
                                "/api/v1/admin/**"
                        )
                )
                .sessionManagement(
                        session -> session
                                .sessionCreationPolicy(
                                        SessionCreationPolicy.STATELESS
                                )
                )
                .authorizeHttpRequests(
                        authorize -> authorize

                                .requestMatchers(
                                        HttpMethod.GET,
                                        "/api/v1/catalog/menu",
                                        "/api/v1/content/site",
                                        "/api/v1/contact",
                                        "/api/v1/media",
                                        "/api/v1/media/**",
                                        "/api/v1/reviews"
                                )
                                .permitAll()

                                .requestMatchers(
                                        "/actuator/health",
                                        "/actuator/health/**",
                                        "/actuator/info",
                                        "/actuator/prometheus"
                                )
                                .permitAll()

                                .requestMatchers(
                                        "/v3/api-docs",
                                        "/v3/api-docs/**",
                                        "/v3/api-docs.yaml",
                                        "/swagger-ui.html",
                                        "/swagger-ui/**"
                                )
                                .permitAll()

                                .requestMatchers(
                                        "/api/v1/admin/media/orphans"
                                )
                                .hasRole("ADMIN")

                                .requestMatchers(
                                        "/api/v1/admin/**"
                                )
                                .hasAnyRole(
                                        "EDITOR",
                                        "ADMIN"
                                )

                                .anyRequest()
                                .denyAll()
                )
                .oauth2ResourceServer(
                        oauth2 -> oauth2.jwt(
                                jwt -> jwt
                                        .jwtAuthenticationConverter(
                                                jwtAuthenticationConverter
                                        )
                        )
                );

        return http.build();
    }

    @Bean
    JwtAuthenticationConverter
    jwtAuthenticationConverter(
            KeycloakClientRoleConverter
                    roleConverter
    ) {

        JwtGrantedAuthoritiesConverter
                scopeConverter =
                new JwtGrantedAuthoritiesConverter();

        JwtAuthenticationConverter
                authenticationConverter =
                new JwtAuthenticationConverter();

        authenticationConverter
                .setPrincipalClaimName(
                        "preferred_username"
                );

        authenticationConverter
                .setJwtGrantedAuthoritiesConverter(
                        jwt -> {
                            LinkedHashSet<
                                    GrantedAuthority
                                    > authorities =
                                    new LinkedHashSet<>();

                            Collection<
                                    GrantedAuthority
                                    > scopes =
                                    scopeConverter.convert(
                                            jwt
                                    );

                            if (scopes != null) {
                                authorities.addAll(
                                        scopes
                                );
                            }

                            Collection<
                                    GrantedAuthority
                                    > roles =
                                    roleConverter.convert(
                                            jwt
                                    );

                            if (roles != null) {
                                authorities.addAll(
                                        roles
                                );
                            }

                            return authorities;
                        }
                );

        return authenticationConverter;
    }
}
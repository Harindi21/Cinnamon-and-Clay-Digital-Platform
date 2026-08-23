package dev.cinnamonandclay.cafe.identity;

import java.util.List;
import java.util.Locale;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin")
class AdminIdentityController {

    @GetMapping("/me")
    AdminIdentityResponse me(
            JwtAuthenticationToken authentication
    ) {
        List<String> roles =
                authentication
                        .getAuthorities()
                        .stream()
                        .map(
                                GrantedAuthority
                                        ::getAuthority
                        )
                        .filter(
                                authority ->
                                        authority
                                                .startsWith(
                                                        "ROLE_"
                                                )
                        )
                        .map(
                                authority ->
                                        authority
                                                .substring(
                                                        "ROLE_"
                                                                .length()
                                                )
                                                .toLowerCase(
                                                        Locale.ROOT
                                                )
                        )
                        .sorted()
                        .toList();

        return new AdminIdentityResponse(
                authentication
                        .getToken()
                        .getSubject(),
                authentication
                        .getToken()
                        .getClaimAsString(
                                "preferred_username"
                        ),
                authentication
                        .getToken()
                        .getClaimAsString(
                                "email"
                        ),
                roles
        );
    }

    record AdminIdentityResponse(
            String subject,
            String username,
            String email,
            List<String> roles
    ) {
    }
}
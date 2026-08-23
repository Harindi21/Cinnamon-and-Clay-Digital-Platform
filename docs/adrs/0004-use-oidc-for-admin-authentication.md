# ADR 0004: Use OIDC for admin authentication

- Status: Accepted
- Date: 2026-08-18

## Context

Administrative operations modify customer-visible business data and therefore require authenticated identities.

Implementing password storage, password reset, MFA, session management and token issuance inside the cafe API would add security-sensitive responsibilities that are not part of the application's core domain.

The administrator application is a native client and cannot safely store a confidential OAuth client secret.

## Decision

Use OpenID Connect for administrator authentication.

The Flutter administrator application will use the OAuth 2.0 Authorization Code flow with PKCE.

The Spring Boot API acts as an OAuth 2.0 resource server and accepts signed JWT access tokens.

The API validates the token issuer, lifetime, signature and intended audience before authorization rules are evaluated.

Local development uses Keycloak.

Production may use another standards-compliant OpenID Connect provider without changing the application's authorization model.

The application does not store administrator passwords.

## Consequences

Authentication credential lifecycle is delegated to the identity provider.

The application remains responsible for authorization decisions.

Administrator access tokens must never be committed to the repository, persisted in application logs or stored in PostgreSQL.

Local development requires an additional identity-provider service.

The Flutter application requires browser-based OIDC redirect handling and secure token storage.

The backend remains independent of Keycloak-specific Java adapters.
# ADR 0008: Use API client roles for administrator authorization

- Status: Accepted
- Date: 2026-08-23

## Context

Authentication proves who an administrator is but does not determine which operations that identity may perform.

Administrative permissions must be enforced by the API rather than relying on Flutter UI visibility.

The authorization model should remain small enough to understand and audit while allowing privileged operations to be separated when necessary.

## Decision

Define authorization roles against the `kirikopi-api` OIDC resource client.

The initial roles are:

`editor` permits normal cafe content-management operations.

`admin` permits full administrative operations and may be required for security-sensitive capabilities introduced later.

Keycloak places these roles in the access token under the `resource_access.kirikopi-api.roles` claim.

The Spring API maps them to `ROLE_EDITOR` and `ROLE_ADMIN`.

Public read endpoints remain accessible without authentication.

Administrative endpoints are placed below `/api/v1/admin`.

Administrative APIs require either `EDITOR` or `ADMIN` unless an endpoint explicitly requires the stronger `ADMIN` role.

The API is the source of truth for authorization.

Client-side Flutter route guards and hidden controls exist only for user experience and are never treated as security controls.

JWT validation includes the expected `kirikopi-api` audience.

## Consequences

Authorization rules are centralized at the API boundary.

Roles issued for unrelated OIDC clients cannot grant Kirikopi API permissions.

Adding new administrator roles requires an explicit authorization-model change rather than silently deriving permissions from UI behaviour.

API authorization remains testable without running the external identity provider.

Role proliferation should be avoided. New roles require a distinct business or security boundary.
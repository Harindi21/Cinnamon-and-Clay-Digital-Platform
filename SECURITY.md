# Security policy

Do not report secrets or exploitable vulnerabilities in a public issue.

Use a private GitHub Security Advisory when available. If a secret is committed, treat it as compromised: revoke/rotate it first, then remove it from repository history if necessary.

## Implemented controls

Repository and supply-chain controls include Gitleaks, CodeQL, Trivy, dependency review, Dependabot, least-privilege workflow permissions and protected-branch/ruleset expectations.

Application controls include:

- OIDC bearer-token validation and server-side administrator/editor RBAC;
- explicit administrator DTOs and bean validation;
- optimistic concurrency for administrator-managed resources;
- hardened JPEG/PNG upload validation and generated object keys;
- append-only administrator audit records with bounded/redacted before/after state;
- request/trace correlation without persisting bearer tokens;
- authenticated allow-listed public cache revalidation;
- PostgreSQL constraints and forward-only Flyway migrations.

Local `.env` values are development placeholders only. Production environments must provide unique secrets for database/object-storage/OIDC/cache-revalidation/Grafana access through an appropriate secret manager or protected environment configuration.

See `docs/architecture/threat-model.md` for the current control/backlog model and `docs/runbooks/secret-leak.md` for secret-response steps.


## Release artifact integrity

Release container images are addressed by immutable digest, scanned for HIGH/CRITICAL vulnerabilities according to the release policy, accompanied by CycloneDX SBOM artifacts and BuildKit attestations, and keyless-signed with Cosign using GitHub OIDC. Environment promotion verifies signatures and digest existence before producing a deployment manifest. No long-lived image-signing private key is stored in repository secrets.


## Android administrator security

The native admin client uses Authorization Code + PKCE through the system browser and stores tokens through `flutter_secure_storage`; administrator passwords are never collected by the app. Android backup/device-transfer rules exclude application data, the production manifest denies cleartext traffic, and only the debug variant permits local HTTP for `adb reverse`. The OIDC callback is pinned to `dev.cinnamonandclay.admin:/oauthredirect` across Dart validation, Android AppAuth configuration and Keycloak.

Release signing material is supplied only by the protected `mobile-release` GitHub Environment. Keystores, passwords and private keys are ignored by Git and must be backed up in a separate secret-management boundary. Android release AABs are checksumed and provenance-attested; store rollout should use Play App Signing/internal testing rather than placing Play service-account credentials in the repository.

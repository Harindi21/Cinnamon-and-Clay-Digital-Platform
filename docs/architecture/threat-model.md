# Lightweight threat model

## Assets

- administrator identity and authorization tokens;
- cafe content/catalog integrity;
- append-only administrator change history;
- customer-visible availability and freshness;
- database and media backups;
- deployment credentials, Android signing material, cache-revalidation secret and repository secrets.

## Important threats

- stolen administrator token or overly broad role;
- mass assignment / missing server-side authorization;
- stored XSS through administrator-managed text;
- malicious or oversized file upload;
- SQL injection or unsafe native queries;
- audit tampering or accidental audit deletion;
- sensitive values leaking into audit/log payloads;
- forged cache-invalidation requests;
- secret leakage through Git, CI logs or images;
- vulnerable dependencies/base images;
- destructive migration or accidental data loss;
- denial of service against public endpoints;
- supply-chain compromise in CI actions/images or Android build tooling;
- malicious app impersonation/callback interception against the native custom-scheme redirect.

## Implemented identity controls

- administrator authentication is delegated through OIDC;
- native clients use Authorization Code with PKCE through the system browser;
- the Android callback URI is pinned across client validation, AppAuth packaging and Keycloak; PKCE limits authorization-code theft even though custom-scheme ownership itself cannot be globally exclusive;
- the API validates JWT issuer, signature, lifetime and audience;
- privileged API routes enforce server-side RBAC;
- CSRF checks remain enabled generally; the stateless bearer-token administrator API path is explicitly excluded because it does not use cookie authentication;
- authorization uses roles belonging specifically to the Cinnamon & Clay API client;
- the resource server is stateless and does not persist access tokens;
- only `admin` may browse the audit trail or perform media orphan cleanup.

## Implemented write/integrity controls

- administrator write endpoints use explicit request DTO allow-lists and bean validation;
- catalog, review, content, contact and media writes use optimistic concurrency versions to prevent silent lost updates;
- public visibility is controlled server-side rather than trusted to Flutter UI state;
- administrator-managed map/social URLs are HTTPS-restricted and WhatsApp numbers use E.164 when enabled;
- destructive business actions use reversible lifecycle state rather than physical deletion;
- media uploads are byte/dimension/pixel bounded, binary-sniffed as JPEG/PNG and stored under generated object keys;
- media replacement uses new-object-then-metadata-switch semantics with compensating cleanup and aged orphan reconciliation;
- Hero/About singleton visibility is enforced in service logic and by a partial database uniqueness constraint;
- successful administrator mutations write a bounded, sanitized audit event in the same transaction where applicable;
- PostgreSQL rejects update/delete/truncate against the audit table.

## Implemented operational controls

- request IDs are bounded/validated and returned to callers; traces, logs, Problem Details and audit events share correlation identifiers when available;
- audit payload sanitization redacts common credential/token field names and bounds depth/size;
- public cache invalidation is server-to-server, allow-listed by tag and protected with a per-environment shared secret using constant-time comparison;
- failed cache invalidation does not roll back a committed business write; the bounded Next.js TTL is the fallback;
- Prometheus/Grafana and alert rules are available through an optional local profile;
- backup, destructive restore and isolated restore-rehearsal scripts are checked into the repository; backup artifacts are Git-ignored;
- tag-triggered releases and promotion require the tagged commit to remain reachable from `main`; promotion resolves source/image coordinates from the published GitHub Release manifest, verifies its checksum and tag-to-commit binding, and requires Cosign signatures issued by this repository's release workflow for the exact promoted tag.

## Controls backlog / deployment work

- production edge rate limiting/WAF policy if traffic requires it;
- immutable third-party action digest pinning after bootstrap;
- production OIDC/key rotation and secret manager integration;
- consider verified Android App Links instead of a custom scheme if a stable production domain and association file are available;
- encrypted off-site database backup retention and PITR;
- object-storage versioning/backup/replication aligned with database recovery;
- centralized log/trace destination with access controls and retention;
- audit retention/archive policy owned outside normal application credentials;
- real Play Console application/service-account boundary and store rollout controls.

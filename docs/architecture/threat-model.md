# Lightweight threat model

## Assets

- admin identity and authorization tokens
- cafe content/catalog integrity
- customer-visible availability
- database and media backups
- deployment credentials and repository secrets

## Important threats to address

- stolen admin token or overly broad role
- mass assignment / missing server-side authorization
- stored XSS through admin-managed text
- malicious or oversized file upload
- SQL injection or unsafe native queries
- secret leakage through Git, CI logs or images
- vulnerable dependencies/base images
- destructive migration or accidental data loss
- denial of service against public endpoints
- supply-chain compromise in CI actions/images

## Implemented identity controls

- administrator authentication is delegated through OIDC;
- native clients use Authorization Code with PKCE;
- the API validates JWT issuer, signature, lifetime and audience;
- privileged API routes enforce server-side RBAC;
- authorization uses roles belonging specifically to the Kirikopi API client;
- the resource server is stateless and does not persist access tokens.

## Controls backlog

- OIDC + least-privilege RBAC
- DTO allow-lists and bean validation
- output escaping and content restrictions
- upload MIME/size/dimension validation
- parameterized persistence APIs
- Gitleaks and secret rotation runbook
- CodeQL, dependency review, Dependabot, Trivy
- backup/restore tests and migration review
- rate limiting at the edge/API gateway if needed
- pin third-party CI actions/images by immutable digest after bootstrap

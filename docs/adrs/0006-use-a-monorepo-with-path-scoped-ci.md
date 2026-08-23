# ADR 0006: Use a monorepo with path-scoped CI

- Status: Accepted
- Date: 2026-08-18

## Context

The website, admin app, backend, infrastructure and architecture docs belong to one product system and are maintained together.

## Decision

Keep all components in one repository. Enforce shared PR standards, security checks and CODEOWNERS. As build time grows, add path filters so unchanged components do not run unnecessarily.

## Consequences

- Cross-stack changes are easy to review atomically.
- Repository governance is centralized.
- CI configuration must remain modular enough to avoid unnecessary cost.

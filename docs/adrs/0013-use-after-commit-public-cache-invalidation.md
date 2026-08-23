# ADR 0013: Use after-commit public cache invalidation

- Status: Accepted
- Date: 2026-08-24

## Context

The public Next.js application caches backend reads for five minutes. That protects the API and keeps the public page fast, but administrators reasonably expect published catalog/content/contact/media/review changes to become visible promptly.

Calling Next.js before the database transaction commits can expose stale data, and making a frontend callback part of the database transaction would couple availability of an optional cache optimization to correctness of the administrator write.

## Decision

Tag each public backend fetch by bounded business capability: `catalog`, `content`, `contact`, `media`, or `reviews`.

After a successful administrator mutation commits, publish an internal change event and make a best-effort authenticated POST to an internal Next.js revalidation route. The route accepts only known tags and uses Next.js tag revalidation.

The callback is protected by a per-environment shared secret. It is server-to-server only and is not exposed to browser JavaScript.

Cache invalidation is deliberately **after commit and best effort**:

- a failed invalidation never rolls back an already committed business change;
- the existing five-minute TTL remains the correctness fallback;
- failures are logged and counted as a metric;
- no distributed transaction is introduced between Spring Boot and Next.js.

## Consequences

Administrator changes normally become visible on the public site on the next request rather than waiting for the TTL.

If the callback is missed, the normal five-minute fetch revalidation window remains the fallback; behavior during a continuing upstream outage follows Next.js stale/error semantics rather than being treated as a freshness guarantee.

The backend gains a small server-to-server dependency on the public web application, but only for freshness optimization. Public API correctness and administrator write availability remain independent.

The shared secret must be rotated and stored as an environment secret outside local development.

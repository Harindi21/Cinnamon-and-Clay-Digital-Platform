# Service-level objectives and indicators

These are **design targets for portfolio/release readiness**, not claims about observed production performance. There is no production traffic history yet. Replace them with measured objectives once a hosting target and real workload exist.

## Public read path

| Objective | Initial target | Indicator |
| --- | ---: | --- |
| Availability | 99.9% monthly design target | proportion of non-5xx public API responses, excluding agreed maintenance |
| Backend latency | p95 < 1 s as an alert guardrail | `http_server_requests_seconds` histogram for public endpoints |
| Content freshness after admin commit | normally next public request; 5 min TTL fallback under normal upstream availability | cache invalidation success metric plus Next.js 300 s TTL |

The local alert for p95 > 1 s is intentionally a guardrail rather than evidence that the target has been met.

## Administrator path

Administrator mutations prioritize correctness over latency. Monitor:

- 5xx/error ratio;
- optimistic-concurrency conflict rate as a product signal rather than server failure;
- audit event rate by action/resource type;
- media upload/replacement failures;
- cache invalidation outcomes.

Every successful administrator mutation should produce a durable audit event unless the operation is explicitly read-only.

## Recovery objectives

Production RPO/RTO are **not yet declared** because they depend on the selected database provider, backup schedule and point-in-time recovery capability.

The repository provides repeatable backup and isolated restore-rehearsal tooling so actual restore duration can be measured. Before production launch:

1. select backup/PITR capability and retention;
2. rehearse a production-like restore;
3. record measured restore duration and acceptable data-loss window;
4. define RTO/RPO from evidence rather than aspiration.

## Error budgets

When production monitoring exists, a 99.9% monthly availability target corresponds to an error budget of approximately 0.1% of covered requests/time. Release decisions should consider error-budget consumption together with severity and business impact rather than treating every transient failure equally.

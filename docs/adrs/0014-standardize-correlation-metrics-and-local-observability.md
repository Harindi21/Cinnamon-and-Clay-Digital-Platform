# ADR 0014: Standardize correlation, metrics and local observability

- Status: Accepted
- Date: 2026-08-24

## Context

Health checks and raw logs are insufficient for diagnosing a production-style application. Operational investigation needs a way to correlate user-visible errors, backend requests, administrator audit events and traces, plus a small set of service indicators that can be visualized and alerted on.

The project should demonstrate these practices without forcing a heavy distributed-observability stack into the default local developer path.

## Decision

Adopt the following operational baseline:

- accept or generate a bounded `X-Request-Id` for every backend request and return it to callers;
- add request ID plus trace/span IDs to log correlation context;
- include request/trace IDs in HTTP Problem Details when available;
- instrument tracing through Spring Boot OpenTelemetry support, with OTLP export opt-in;
- expose Prometheus-format Actuator metrics;
- record application counters for administrator audit events and public cache invalidation outcomes;
- provide a local, optional Docker Compose `observability` profile with Prometheus, alert rules and a provisioned Grafana dashboard;
- use structured ECS console logging in the production Spring profile while retaining readable local logs by default.

The initial operational indicators are backend availability, request rate, 5xx ratio and p95 latency. Alerts are intentionally small and actionable rather than attempting to monitor every metric.

## Consequences

A request ID can be copied from a failed API response into logs and audit records to speed diagnosis.

Tracing can be exported when a production collector is selected without changing application instrumentation.

Prometheus and Grafana are optional local dependencies, so developers who only need business functionality do not pay the additional resource cost.

The local alert thresholds are examples and must be calibrated from production traffic before they become contractual SLO alerts.

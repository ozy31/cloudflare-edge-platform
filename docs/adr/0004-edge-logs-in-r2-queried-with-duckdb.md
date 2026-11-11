# 0004. Edge logs in R2, queried with DuckDB

**Status:** accepted

## Context
During an edge incident we need raw request logs: who is blocked, by which rule, what reached
the origin. The dashboard samples and aggregates. A SIEM works, but costs money per GB ingested,
for logs that are mostly read during incidents.

## Decision
Logpush writes the `http_requests` dataset to an R2 bucket as NDJSON, with 30-day retention via
a lifecycle rule. R2 has no egress fees. Investigations use DuckDB directly on the bucket, with
version-controlled queries in `analytics/queries/`. The queries are tested against synthetic
logs with known incidents.

## Consequences
- Cheap to keep, and fast enough for ad-hoc incident work. No always-on infrastructure.
- No real-time alerting from these logs. Alerting comes from Cloudflare notifications (see
  `modules/notifications`).
- Logs contain client IPs, which are personal data. Retention is capped at 365 days by
  validation, and the bucket gets a dedicated read-only token for analysis.

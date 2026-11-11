# Edge log analytics

Logpush writes HTTP request logs to R2 as NDJSON (`terraform/modules/logpush`).
These DuckDB queries answer the questions that come up during an edge
incident, directly on those files:

| Query | Question |
|---|---|
| `top_blocked_ips` | Who is the edge blocking, and with which rules? |
| `credential_stuffing` | Who is guessing passwords, and how much got past rate limiting? |
| `waf_false_positives` | Which rule is blocking real users? |
| `origin_errors` | Is the origin failing, or is the edge blocking? |
| `cache_efficiency` | Are static assets actually cached? |

## Try it locally

```bash
python -m venv .venv && .venv/bin/pip install -r analytics/requirements.txt
.venv/bin/python analytics/generate.py          # synthetic logs with 4 injected incidents
.venv/bin/python analytics/queries.py analytics/data/http_requests.ndjson
```

The generated data uses documentation IP ranges only (RFC 5737).

## On real logs in R2

DuckDB reads R2 through its S3 API with a read-only R2 token:

```sql
INSTALL httpfs; LOAD httpfs;
CREATE SECRET r2 (TYPE r2, KEY_ID getenv('R2_KEY_ID'), SECRET getenv('R2_SECRET'), ACCOUNT_ID getenv('CF_ACCOUNT_ID'));
```

then pass `r2://edge-http-logs/http_requests/20261101/*.log.gz` as the source.

## Tests

`pytest analytics/tests` generates the synthetic logs and checks that each
query finds exactly the injected incident and nothing in the baseline traffic.

-- Origin 5xx per minute, to separate "the origin is failing" from "the
-- edge is blocking". Only minutes above 5% errors are returned.
SELECT
    date_trunc('minute', ts)                                         AS minute,
    count(*) FILTER (WHERE OriginResponseStatus <> 0)                AS origin_requests,
    count(*) FILTER (WHERE OriginResponseStatus >= 500)              AS origin_5xx,
    round(100.0 * count(*) FILTER (WHERE OriginResponseStatus >= 500)
          / nullif(count(*) FILTER (WHERE OriginResponseStatus <> 0), 0), 1) AS pct_5xx,
    quantile_cont(OriginResponseDurationMs, 0.95)
        FILTER (WHERE OriginResponseStatus <> 0)                     AS p95_origin_ms
FROM requests
GROUP BY 1
HAVING pct_5xx > 5
ORDER BY 1;

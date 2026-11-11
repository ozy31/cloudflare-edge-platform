-- Cache hit ratio for cacheable content, per path. Low ratios on static
-- assets usually mean a missing fingerprint or a Vary/cookie problem.
SELECT
    ClientRequestPath                                                     AS path,
    count(*)                                                              AS requests,
    round(100.0 * count(*) FILTER (WHERE CacheCacheStatus = 'hit') / count(*), 1) AS hit_pct
FROM requests
WHERE CacheCacheStatus <> 'dynamic'
GROUP BY 1
ORDER BY requests DESC
LIMIT 20;

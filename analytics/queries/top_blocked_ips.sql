-- Who is the edge blocking, and with which rules?
-- First stop when an alert fires for a spike in blocked requests.
SELECT
    ClientIP                                   AS client_ip,
    count(*)                                   AS blocked,
    count(DISTINCT ClientRequestPath)          AS distinct_paths,
    string_agg(DISTINCT SecurityRuleID, ', ')  AS rules,
    min(ts)                                    AS first_seen,
    max(ts)                                    AS last_seen
FROM requests
WHERE SecurityAction = 'block'
GROUP BY ClientIP
HAVING count(*) >= 10
ORDER BY blocked DESC
LIMIT 20;

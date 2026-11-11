-- Rules that are probably blocking real users.
-- A rule is suspicious when most of what it blocks looks human (high bot
-- score, browser user agent, low attack score) and comes from many
-- different clients rather than a few attackers.
SELECT
    SecurityRuleID                                              AS rule_id,
    any_value(SecurityRuleDescription)                          AS description,
    ClientRequestPath                                           AS path,
    count(*)                                                    AS blocked,
    count(DISTINCT ClientIP)                                    AS distinct_clients,
    round(avg(BotScore), 1)                                     AS avg_bot_score,
    round(100.0 * count(*) FILTER (WHERE ClientRequestUserAgent LIKE 'Mozilla/5.0 (%') / count(*), 1) AS pct_browser_ua
FROM requests
WHERE SecurityAction = 'block'
GROUP BY SecurityRuleID, ClientRequestPath
HAVING avg(BotScore) >= 50
   AND count(DISTINCT ClientIP) >= 20
   AND count(*) FILTER (WHERE ClientRequestUserAgent LIKE 'Mozilla/5.0 (%') >= 0.8 * count(*)
ORDER BY blocked DESC;

-- Login abuse: clients with many login attempts and a low bot score.
-- "rate_limited" shows how much the login_bruteforce rule already caught;
-- "reached_origin" is what got through to the application.
SELECT
    ClientIP                                                  AS client_ip,
    count(*)                                                  AS attempts,
    count(*) FILTER (WHERE SecurityAction = 'block')          AS rate_limited,
    count(*) FILTER (WHERE OriginResponseStatus <> 0)         AS reached_origin,
    round(avg(BotScore), 1)                                   AS avg_bot_score,
    any_value(ClientRequestUserAgent)                         AS user_agent
FROM requests
WHERE ClientRequestPath = '/api/auth/login' AND ClientRequestMethod = 'POST'
GROUP BY ClientIP
HAVING count(*) >= 50 AND avg(BotScore) < 30
ORDER BY attempts DESC;

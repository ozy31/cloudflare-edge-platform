# Runbook: credential stuffing on login

**Signal:** `credential_stuffing.sql` returns clients, login failure rate
rises, or `login_bruteforce` rate-limit blocks spike.

1. Check `reached_origin`: how many attempts got past rate limiting. That number is what the
   application had to handle.
2. If attempts are distributed (many IPs, few requests each), per-IP rate limiting will not hold.
   Enable Turnstile on the login form (`turnstile_domains`) and tighten the
   `challenge_empty_user_agent` rule.
3. Tell the application team which accounts were targeted, so they can force password resets
   where logins succeeded.
4. Lower `requests` for `login_bruteforce` only with data: the query's attempts-per-IP
   distribution shows where real users stop.

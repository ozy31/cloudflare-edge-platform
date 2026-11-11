# 0003. Rate limit sizing

**Status:** accepted

## Context
Rate limits that are too tight lock out real users behind shared IPs (offices, mobile carrier
NAT); limits that are too loose do nothing. Paid plans also cap the number of rules.

## Decision
- **Login** (`POST /api/auth/login`): 10 requests per 60 s per IP per data centre, then a
  10-minute block. A person retrying a forgotten password stays well below this; a credential
  stuffing tool does not.
- **API** (`/api/*`): 200 requests per 10 s, then a managed challenge rather than a block, so a
  busy NAT gateway degrades to a challenge instead of an outage.
- Counting is per `ip.src` and `cf.colo.id`, which is how Cloudflare counts on non-Enterprise
  plans.

## Consequences
- The numbers are a starting point. `credential_stuffing.sql` shows the attempts-per-IP
  distribution, so changes are based on data rather than guesses.
- Distributed attacks (many IPs, few requests each) are out of scope for rate limiting. The
  answer for those is Turnstile on the login form.

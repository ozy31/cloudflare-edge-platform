# Runbook: WAF blocking real users

**Signal:** users report 403s, or `waf_false_positives.sql` returns a row.
The query flags rules whose blocks look human: high bot score, browser user
agents, many different clients.

## 1. Confirm
- Take a Ray ID from the user (it is on the Cloudflare error page) and look it up in Security
  Events. Check which rule matched and why.
- Run `waf_false_positives.sql` to see how many clients are affected.

## 2. Fix, narrowest first
1. **Custom rule:** tighten the expression in `policies/waf-custom-rules.yaml`, for example by
   excluding the path or method. Add a test case, then open a PR.
2. **Managed rule:** override that single rule ID to `managed_challenge` or disable it for the
   affected path. Never lower the sensitivity of the whole managed ruleset.
3. **Emergency only:** set `enabled: false` on the rule in YAML and apply. Open a follow-up
   ticket to re-enable it.

## 3. Afterwards
Every disabled or loosened rule gets an owner and a date to be revisited.

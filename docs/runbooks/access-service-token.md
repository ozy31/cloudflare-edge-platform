# Runbook: rotating an Access service token

**Alert:** `service_token_expiry` (`expiring_service_token_alert`).

1. Find the token by name (`edge-<env>-<client>`) in `terraform output` (client IDs only).
2. Rotate it: `terraform apply -replace='module.access[0].cloudflare_zero_trust_access_service_token.machine["<client>"]'`.
3. Read the new client ID and secret from state, from a trusted machine, and update the
   consumer's secret store (CI secret, uptime checker).
4. Verify that the consumer gets 200 rather than a 302 to the login page.

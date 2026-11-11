# Runbook: HTTP DDoS

**Alert:** `ddos_l7` (Cloudflare `dos_attack_l7`). Cloudflare is already
mitigating; the question is whether users are affected.

## 1. Is the origin healthy?
- Origin 5xx and latency: `analytics/queries/origin_errors.sql` on the last hour of logs, or the
  Cloudflare dashboard → Analytics → Traffic, filtered on origin status.
- Cluster side: pod CPU and saturation on the services behind the tunnel; cloudflared replicas ready.

If the origin is fine, the mitigation is working. Watch for 15 minutes, then write a short note.

## 2. If users are affected
1. Find what the attack targets: `top_blocked_ips.sql` and a breakdown by path and user agent.
2. Add a **temporary** rule to `policies/waf-custom-rules.yaml` (usually `managed_challenge` on the
   targeted path, or a block on an obvious user agent). Open a PR and apply it. Terraform keeps
   the change reviewable even under pressure.
3. Only as a last resort, raise `security_level` to `under_attack` for the zone. Every visitor
   then gets a challenge, and API clients without a browser will break.

## 3. Afterwards
- Remove temporary rules within 24 hours, or convert them into permanent, documented ones.
- Postmortem: what reached the origin, how long, and which alert or dashboard would have shown it sooner.

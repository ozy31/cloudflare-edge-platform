# Runbook: Cloudflare Tunnel down or degraded

**Alert:** `tunnel_health` (`tunnel_health_event`). With no public load
balancer, a dead tunnel means the site is down.

## 1. Check the connectors
```bash
kubectl -n cloudflared get pods -o wide
kubectl -n cloudflared logs deploy/cloudflared --tail=100
```
- **Pods not ready:** check the readiness endpoint (`/ready` on port 2000) and recent events.
- **Logs show `Unauthorized` or `token`:** the token Secret is wrong or the tunnel was deleted.
  Re-create it with `terraform output -raw tunnel_token | hack/tunnel-secret.sh`.
- **Logs show connection errors to the edge:** check egress. The NetworkPolicy allows 7844
  (UDP/TCP) and 443. A cluster or cloud firewall change is the usual cause. cloudflared falls back
  from QUIC to HTTP/2 by itself if UDP is blocked.

## 2. Check routing
- `terraform plan` should show no drift in `cloudflare_zero_trust_tunnel_cloudflared_config`.
- A hostname returning 404 from Cloudflare means it is missing from `tunnel_routes`. That 404
  comes from the catch-all rule, not from the application.

## 3. Recovery
- `kubectl -n cloudflared rollout restart deploy/cloudflared` is safe: the PDB keeps one replica
  up, and `maxUnavailable: 0` means a new pod is ready before an old one stops.
- If a node pool lost egress, schedule cloudflared elsewhere until it is fixed.

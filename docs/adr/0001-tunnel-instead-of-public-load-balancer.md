# 0001. Cloudflare Tunnel instead of a public load balancer

**Status:** accepted

## Context
A public load balancer gives the cluster a reachable IP. Anyone who finds it, for example
through an old DNS record, certificate transparency logs or a scan, can bypass the WAF, rate
limits and Access completely. Locking the origin down to Cloudflare's IP ranges or using
authenticated origin pulls helps, but both are easy to get wrong and drift over time.

## Decision
Expose HTTP services only through Cloudflare Tunnel. cloudflared runs in the cluster (two
replicas, PDB, restricted Pod Security) and makes outbound connections only. Ingress
(hostname → service) is managed remotely by Terraform, so routing changes are reviewed like any
other change. Unmatched hostnames get a 404.

## Consequences
- The cluster has no inbound attack surface for HTTP; the e2e test asserts there are no
  LoadBalancer or NodePort services.
- The tunnel is now a critical dependency. It gets its own alert, runbook and two replicas.
- Non-HTTP traffic (for example SMTP) cannot go through the tunnel. Such records must be
  unproxied, and the DNS module requires a written reason for each one.
- cloudflared's NetworkPolicy limits which namespaces the tunnel can reach. Exposing a namespace
  is an explicit label (`edge.cloudflare.com/exposed=true`).

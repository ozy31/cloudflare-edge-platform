# cloudflare-edge-platform

Cloudflare in front of a Kubernetes platform, managed entirely as code.

The goal is a production edge that a small platform team can own:

- **Zone baseline:** strict TLS, HSTS and DNS defined in Terraform
- **WAF:** managed rulesets plus custom rules that live in version control
- **Rate limiting and bot defence** for login and API paths
- **Cloudflare Tunnel:** the cluster has no public load balancer at all
- **Cloudflare Access:** internal tools (Argo CD, Grafana) behind SSO, no VPN
- **Logpush to R2**, with ready-made queries for attack and false-positive analysis
- **Runbooks** for the incidents that actually happen at the edge

> Work in progress. Sections are added as each part lands with its tests.

## Layout

```
terraform/            root stack (provider, variables, module wiring)
terraform/modules/    one module per concern
versions.env          pinned tool versions (Makefile + CI)
```

## Usage

No Cloudflare account is needed for the checks:

```bash
make check      # fmt, validate, tflint, terraform test
```

To apply against a real zone, copy `terraform/terraform.tfvars.example` to
`terraform/terraform.tfvars`, export `CLOUDFLARE_API_TOKEN`, then run
`terraform -chdir=terraform plan`.

## Tests

`terraform test` runs against a mocked Cloudflare provider, so it checks the
real provider schema and our own rules without an account:

- **Root stack** (`terraform/tests/`): secure defaults, optional parts off by
  default, WAF and rate-limit rules loaded from YAML, a full setup with Tunnel,
  Access and Turnstile, and inputs that must be rejected.
- **Modules** (`terraform/modules/*/tests/`):
  - DNS: an unproxied origin needs a reason; anti-spoofing records.
  - Tunnel: routes only to in-cluster services; catch-all 404; origin TLS
    verified.
  - WAF and rate limits: unknown actions, duplicate refs, plan limits.

## Kubernetes e2e

`make e2e` creates a kind cluster and checks the cloudflared deployment:

- The manifests are admitted under the `restricted` Pod Security Standard.
- The cluster exposes no LoadBalancer or NodePort services.
- NetworkPolicy isolation, tested with a probe pod that carries cloudflared's
  labels: it reaches namespaces labelled `edge.cloudflare.com/exposed=true`,
  but not unlabelled namespaces or the Kubernetes API server.

Nothing is exposed to the internet by default. `E2E_PUBLIC_TUNNEL=1 make e2e`
adds a check through Cloudflare's real edge, using an account-less quick
tunnel. **It makes the demo origin publicly reachable** at a random
`trycloudflare.com` URL until the test finishes and removes the tunnel.

## Edge log analytics

`terraform/modules/logpush` pushes HTTP request logs to R2 with 30-day
retention. [`analytics/`](analytics/README.md) has DuckDB queries for blocked
clients, credential stuffing, WAF false positives, origin errors and cache
efficiency. They are tested against synthetic logs with known incidents
(`make analytics`).

## Secrets

The API token is only read from the environment. R2 credentials for Logpush are
sensitive variables passed as `TF_VAR_r2_*`. Nothing in this repository
contains account IDs, zone IDs or tokens, and `terraform.tfvars` is git-ignored.

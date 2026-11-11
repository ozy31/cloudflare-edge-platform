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
make check      # fmt, validate (real provider schema), tflint
```

To apply against a real zone, copy `terraform/terraform.tfvars.example` to
`terraform/terraform.tfvars`, export `CLOUDFLARE_API_TOKEN`, then run
`terraform -chdir=terraform plan`.

## Secrets

The API token is only read from the environment. Nothing in this repository
contains account IDs, zone IDs or tokens, and `terraform.tfvars` is git-ignored.

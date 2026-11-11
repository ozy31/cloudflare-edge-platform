# 0002. WAF and rate-limit rules as YAML, reviewed in pull requests

**Status:** accepted

## Context
Edge rules change often and under pressure (an attack, a false positive). Dashboard edits are
fast but leave no review and no history, and drift from Terraform state.

## Decision
Custom WAF rules and rate limits live in `policies/*.yaml`. Application teams can propose a rule
without knowing Terraform. Terraform loads the files, and preconditions reject unknown actions,
duplicate refs, unsupported periods and more rules than the plan allows, before anything reaches
Cloudflare. Mocked `terraform test` runs in CI on every change.

## Consequences
- Every rule has an author, a review and a commit message. The runbooks say to change the YAML
  even during an incident.
- Emergency changes take a few minutes longer than clicking in the dashboard. We accept that;
  `security_level = under_attack` remains available as the one-switch fallback.
- Expression syntax is only fully validated by the Cloudflare API at apply time. The mocked
  tests check structure, not expression semantics.

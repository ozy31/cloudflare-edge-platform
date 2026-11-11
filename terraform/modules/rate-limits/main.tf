locals {
  rules = [
    for r in var.rules : {
      ref         = r.ref
      description = r.description
      expression  = trimspace(replace(r.expression, "\n", " "))
      action      = r.action
      enabled     = try(r.enabled, true)
      ratelimit = {
        characteristics     = ["cf.colo.id", "ip.src"]
        period              = r.period
        requests_per_period = r.requests
        # managed_challenge needs no timeout; the challenge itself is the cooldown
        mitigation_timeout = r.action == "block" ? r.timeout : 0
      }
    }
  ]

  allowed_periods = [10, 60, 120, 300, 600, 3600]
}

resource "cloudflare_ruleset" "this" {
  zone_id     = var.zone_id
  name        = "${var.name}-rate-limits"
  description = "Rate limiting rules from policies/rate-limits.yaml"
  kind        = "zone"
  phase       = "http_ratelimit"
  rules       = local.rules

  lifecycle {
    precondition {
      condition     = alltrue([for r in local.rules : contains(local.allowed_periods, r.ratelimit.period)])
      error_message = "Rate limit period must be one of 10, 60, 120, 300, 600 or 3600 seconds."
    }
    precondition {
      condition     = alltrue([for r in local.rules : contains(["block", "managed_challenge"], r.action)])
      error_message = "Rate limit action must be block or managed_challenge."
    }
    precondition {
      condition     = length(local.rules) <= var.max_rules
      error_message = "More rate limiting rules than the zone plan allows (max_rules)."
    }
  }
}

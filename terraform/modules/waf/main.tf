locals {
  allowed_actions = ["block", "managed_challenge", "js_challenge", "skip"]

  custom_rules = [
    for r in var.custom_rules : {
      ref         = r.ref
      description = r.description
      action      = r.action
      expression  = trimspace(replace(r.expression, "\n", " "))
      enabled     = try(r.enabled, true)
      # "skip" stops the remaining custom rules for matching traffic only;
      # managed rules still apply.
      action_parameters = r.action == "skip" ? { ruleset = "current" } : null
      logging           = r.action == "skip" ? { enabled = true } : null
    }
  ]
}

# Managed rulesets (Cloudflare managed rules and OWASP core). Which ones
# exist depends on the plan; IDs are inputs so the free managed ruleset can
# be used on a free zone.
resource "cloudflare_ruleset" "managed" {
  count = length(var.managed_rulesets) > 0 ? 1 : 0

  zone_id     = var.zone_id
  name        = "${var.name}-managed-waf"
  description = "Managed WAF rulesets"
  kind        = "zone"
  phase       = "http_request_firewall_managed"

  rules = [
    for m in var.managed_rulesets : {
      ref         = m.ref
      description = "Execute ${m.ref}"
      action      = "execute"
      expression  = "true"
      enabled     = true
      action_parameters = {
        id = m.id
        overrides = m.sensitivity == null ? null : {
          action            = m.action
          enabled           = true
          sensitivity_level = m.sensitivity
        }
      }
    }
  ]
}

resource "cloudflare_ruleset" "custom" {
  zone_id     = var.zone_id
  name        = "${var.name}-custom-waf"
  description = "Custom WAF rules from policies/waf-custom-rules.yaml"
  kind        = "zone"
  phase       = "http_request_firewall_custom"
  rules       = local.custom_rules

  lifecycle {
    precondition {
      condition     = alltrue([for r in local.custom_rules : contains(local.allowed_actions, r.action)])
      error_message = "A custom WAF rule uses an action that is not allowed (block, managed_challenge, js_challenge, skip)."
    }
    precondition {
      condition     = length(distinct([for r in local.custom_rules : r.ref])) == length(local.custom_rules)
      error_message = "Custom WAF rule refs must be unique."
    }
  }
}

output "name" {
  description = "Name prefix used for resources created by this stack."
  value       = "${local.name} (${var.zone_name})"
}

output "zone_settings" {
  description = "Zone settings managed by this stack."
  value       = module.zone_baseline.settings
}

output "hostnames" {
  description = "Application hostnames managed in DNS."
  value       = module.dns.hostnames
}

output "waf_custom_rules" {
  description = "Custom WAF rules in evaluation order."
  value       = module.waf.custom_rule_refs
}

output "rate_limit_rules" {
  description = "Rate limiting rules in evaluation order."
  value       = module.rate_limits.rule_refs
}

output "turnstile_sitekey" {
  description = "Public Turnstile site key (null when Turnstile is not enabled)."
  value       = try(module.turnstile[0].sitekey, null)
}

output "custom_rule_refs" {
  description = "Refs of the custom rules, in evaluation order."
  value       = [for r in local.custom_rules : r.ref]
}

output "custom_ruleset_id" {
  description = "ID of the custom WAF ruleset."
  value       = cloudflare_ruleset.custom.id
}

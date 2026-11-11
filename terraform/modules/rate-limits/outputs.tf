output "rule_refs" {
  description = "Refs of the rate limiting rules."
  value       = [for r in local.rules : r.ref]
}

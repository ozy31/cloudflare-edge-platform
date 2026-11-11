output "alert_types" {
  description = "Enabled alerts and their Cloudflare alert types."
  value       = { for k, v in local.enabled_alerts : k => v.type }
}

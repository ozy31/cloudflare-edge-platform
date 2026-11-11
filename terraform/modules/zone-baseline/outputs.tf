output "settings" {
  description = "Settings applied to the zone, keyed by setting ID."
  value       = merge(local.settings, { security_header = "hsts" })
}

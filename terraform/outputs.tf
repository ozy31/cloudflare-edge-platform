output "name" {
  description = "Name prefix used for resources created by this stack."
  value       = "${local.name} (${var.zone_name})"
}

output "zone_settings" {
  description = "Zone settings managed by this stack."
  value       = module.zone_baseline.settings
}

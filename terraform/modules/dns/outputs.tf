output "hostnames" {
  description = "Application hostnames managed by this module."
  value       = { for k, r in cloudflare_dns_record.app : k => r.name }
}

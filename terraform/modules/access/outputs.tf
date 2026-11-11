output "applications" {
  description = "Protected hostnames."
  value       = { for k, a in cloudflare_zero_trust_access_application.app : k => a.domain }
}

output "service_token_client_ids" {
  description = "Client IDs of the service tokens (the secrets are only in state; rotate them from there)."
  value       = { for k, t in cloudflare_zero_trust_access_service_token.machine : k => t.client_id }
}

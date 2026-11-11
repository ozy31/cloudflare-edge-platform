output "tunnel_id" {
  description = "Tunnel ID."
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "hostnames" {
  description = "Hostnames served through the tunnel."
  value       = [for r in var.routes : r.hostname]
}

output "token" {
  description = "cloudflared connector token. Pipe it straight into a Kubernetes Secret; never write it to disk."
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.this.token
  sensitive   = true
}

# A remotely-managed Cloudflare Tunnel. cloudflared runs inside the cluster
# and dials out to Cloudflare, so the cluster needs no public load balancer
# and no inbound firewall rule. Ingress (hostname -> service) is defined
# here, not in the cluster, so routing changes go through Terraform review.

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id = var.account_id
  name       = var.name
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id

  config = {
    ingress = concat(
      [
        for h in var.routes : {
          hostname = h.hostname
          service  = h.service
          origin_request = {
            connect_timeout = 10
            http2_origin    = h.http2_origin
            no_tls_verify   = false
          }
        }
      ],
      # Anything that does not match a hostname gets a 404 instead of
      # reaching some default service.
      [{ service = "http_status:404" }],
    )
  }
}

resource "cloudflare_dns_record" "route" {
  for_each = { for r in var.routes : r.hostname => r }

  zone_id = var.zone_id
  name    = each.key
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
  comment = "tunnel ${var.name}"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "this" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

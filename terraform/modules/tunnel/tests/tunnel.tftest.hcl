mock_provider "cloudflare" {}

variables {
  account_id = "fedcba9876543210fedcba9876543210"
  zone_id    = "0123456789abcdef0123456789abcdef"
  name       = "test"
  routes = [
    { hostname = "app.example.com", service = "http://web.app.svc.cluster.local:80" },
  ]
}

run "rejects_route_outside_cluster" {
  command = plan
  variables {
    routes = [{ hostname = "app.example.com", service = "http://203.0.113.10:8080" }]
  }
  expect_failures = [var.routes]
}

run "rejects_duplicate_hostnames" {
  command = plan
  variables {
    routes = [
      { hostname = "app.example.com", service = "http://a.app.svc.cluster.local" },
      { hostname = "app.example.com", service = "http://b.app.svc.cluster.local" },
    ]
  }
  expect_failures = [var.routes]
}

run "unmatched_hostnames_get_404" {
  command = apply
  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.this.config.ingress[length(cloudflare_zero_trust_tunnel_cloudflared_config.this.config.ingress) - 1].service == "http_status:404"
    error_message = "The last ingress rule must be a 404 catch-all."
  }
}

run "dns_points_at_tunnel" {
  command = apply
  assert {
    condition     = endswith(cloudflare_dns_record.route["app.example.com"].content, ".cfargotunnel.com") && cloudflare_dns_record.route["app.example.com"].proxied
    error_message = "Tunnel hostnames must be proxied CNAMEs to <tunnel-id>.cfargotunnel.com."
  }
}

run "origin_tls_is_verified" {
  command = apply
  assert {
    condition     = alltrue([for i in slice(cloudflare_zero_trust_tunnel_cloudflared_config.this.config.ingress, 0, 1) : i.origin_request.no_tls_verify == false])
    error_message = "Origin TLS verification must stay on."
  }
}

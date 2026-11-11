# Everything enabled: tunnel, Access, Turnstile.

mock_provider "cloudflare" {}

variables {
  account_id        = "fedcba9876543210fedcba9876543210"
  zone_id           = "0123456789abcdef0123456789abcdef"
  zone_name         = "example.com"
  turnstile_domains = ["app.example.com"]
  tunnel_routes = [
    { hostname = "app.example.com", service = "http://web.app.svc.cluster.local:80" },
    { hostname = "argocd.example.com", service = "https://argocd-server.argocd.svc.cluster.local:443", http2_origin = true },
  ]
  logpush              = { enabled = true }
  r2_access_key_id     = "test-key-id"
  r2_secret_access_key = "test-secret"
  access = {
    applications = [
      { name = "argocd", hostname = "argocd.example.com", allow_machines = true },
      { name = "grafana", hostname = "grafana.example.com" },
    ]
    allowed_email_domains = ["example.com"]
    service_tokens        = ["ci"]
  }
}

run "tunnel_routes" {
  command = apply # mocked: computed IDs become known

  assert {
    condition     = module.tunnel[0].hostnames == ["app.example.com", "argocd.example.com"]
    error_message = "Tunnel hostnames do not match the routes."
  }
  assert {
    condition     = output.tunnel_token != null
    error_message = "Tunnel token must be exposed as a sensitive output."
  }
}

run "access_protects_internal_tools" {
  command = apply

  assert {
    condition     = keys(output.access_applications) == ["argocd", "grafana"]
    error_message = "Both internal tools must be behind Access."
  }
  assert {
    condition     = length(module.access[0].service_token_client_ids) == 1
    error_message = "One service token (ci) expected."
  }
}

run "turnstile_enabled" {
  command = apply

  assert {
    condition     = output.turnstile_sitekey != null
    error_message = "Turnstile site key must be output when Turnstile is enabled."
  }
}

run "logpush_to_r2" {
  command = apply

  assert {
    condition     = output.logpush_bucket == "edge-http-logs"
    error_message = "Logs must go to the R2 bucket."
  }
}

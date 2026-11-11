# Inputs that must be rejected before anything reaches Cloudflare.

mock_provider "cloudflare" {}

variables {
  account_id = "fedcba9876543210fedcba9876543210"
  zone_id    = "0123456789abcdef0123456789abcdef"
  zone_name  = "example.com"
}

run "rejects_malformed_zone_id" {
  command = plan
  variables {
    zone_id = "not-a-zone-id"
  }
  expect_failures = [var.zone_id]
}

run "allows_explained_unproxied_record" {
  command = plan
  variables {
    dns_records = {
      mail = { name = "mail", type = "A", content = "203.0.113.20", proxied = false, comment = "SMTP cannot be proxied" }
    }
  }
}

run "rejects_access_nobody_can_use" {
  command = plan
  variables {
    access = { applications = [{ name = "grafana", hostname = "grafana.example.com" }] }
  }
  expect_failures = [var.access]
}

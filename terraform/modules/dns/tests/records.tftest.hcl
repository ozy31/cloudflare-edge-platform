mock_provider "cloudflare" {}

variables {
  zone_id = "0123456789abcdef0123456789abcdef"
}

run "rejects_unexplained_origin_exposure" {
  command = plan
  variables {
    records = { origin = { name = "origin", type = "A", content = "203.0.113.10", proxied = false } }
  }
  expect_failures = [var.records]
}

run "proxied_records_use_automatic_ttl" {
  command = plan
  variables {
    records = { app = { name = "app", type = "CNAME", content = "lb.example.net" } }
  }
  assert {
    condition     = cloudflare_dns_record.app["app"].proxied && cloudflare_dns_record.app["app"].ttl == 1
    error_message = "Records are proxied by default, with automatic TTL."
  }
}

run "no_mail_domain_rejects_spoofing" {
  command = plan
  assert {
    condition     = length(cloudflare_dns_record.spf_null) == 1 && length(cloudflare_dns_record.dmarc_reject) == 1
    error_message = "A zone that sends no mail must publish null SPF and DMARC reject."
  }
  assert {
    condition     = strcontains(cloudflare_dns_record.dmarc_reject[0].content, "p=reject")
    error_message = "DMARC policy must be reject."
  }
}

run "mail_domain_skips_null_records" {
  command = plan
  variables {
    sends_mail = true
  }
  assert {
    condition     = length(cloudflare_dns_record.spf_null) == 0
    error_message = "Null SPF must not be published when the zone sends mail."
  }
}

run "caa_limits_issuers" {
  command = plan
  assert {
    condition     = contains(keys(cloudflare_dns_record.caa), "letsencrypt.org")
    error_message = "CAA must allow the configured issuers."
  }
}

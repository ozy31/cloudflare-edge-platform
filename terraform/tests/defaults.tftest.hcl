# Plan the stack with only the required inputs, against a mocked provider.
# This checks the real provider schema and the defaults we rely on, without
# a Cloudflare account.

mock_provider "cloudflare" {}

variables {
  account_id = "fedcba9876543210fedcba9876543210"
  zone_id    = "0123456789abcdef0123456789abcdef"
  zone_name  = "example.com"
}

run "zone_baseline_is_strict" {
  command = plan

  assert {
    condition     = module.zone_baseline.settings["ssl"] == "strict"
    error_message = "SSL mode must be strict (full with origin certificate validation)."
  }
  assert {
    condition     = module.zone_baseline.settings["min_tls_version"] == "1.2"
    error_message = "Minimum TLS must default to 1.2."
  }
  assert {
    condition     = module.zone_baseline.settings["0rtt"] == "off"
    error_message = "0-RTT must stay off (replayable requests)."
  }
}

run "optional_parts_are_off_by_default" {
  command = plan

  assert {
    condition     = length(module.tunnel) == 0 && length(module.access) == 0 && length(module.turnstile) == 0
    error_message = "Tunnel, Access and Turnstile must only be created when configured."
  }
}

run "mail_spoofing_protection" {
  command = plan

  assert {
    condition     = length(module.dns.hostnames) == 0
    error_message = "No application records by default."
  }
}

run "waf_rules_load_from_yaml" {
  command = plan

  assert {
    condition     = module.waf.custom_rule_refs[0] == "allow_verified_bots"
    error_message = "The verified-bot skip rule must be evaluated first."
  }
  assert {
    condition     = contains(module.waf.custom_rule_refs, "block_internal_paths_publicly")
    error_message = "Metrics and debug paths must be blocked at the edge."
  }
}

run "rate_limits_load_from_yaml" {
  command = plan

  assert {
    condition     = output.rate_limit_rules == ["login_bruteforce", "api_burst"]
    error_message = "Unexpected rate limiting rules."
  }
}

mock_provider "cloudflare" {}

variables {
  zone_id = "0123456789abcdef0123456789abcdef"
  name    = "test"
}

run "rejects_unsupported_period" {
  command = plan
  variables {
    rules = [{ ref = "x", description = "x", expression = "true", period = 30, requests = 10, timeout = 60, action = "block" }]
  }
  expect_failures = [cloudflare_ruleset.this]
}

run "rejects_too_many_rules_for_plan" {
  command = plan
  variables {
    max_rules = 1
    rules = [
      { ref = "a", description = "a", expression = "true", period = 10, requests = 10, timeout = 60, action = "block" },
      { ref = "b", description = "b", expression = "true", period = 10, requests = 10, timeout = 60, action = "block" },
    ]
  }
  expect_failures = [cloudflare_ruleset.this]
}

run "challenge_has_no_timeout" {
  command = plan
  variables {
    rules = [{ ref = "a", description = "a", expression = "true", period = 10, requests = 10, timeout = 60, action = "managed_challenge" }]
  }
  assert {
    condition     = cloudflare_ruleset.this.rules[0].ratelimit.mitigation_timeout == 0
    error_message = "managed_challenge rules must not set a mitigation timeout."
  }
}

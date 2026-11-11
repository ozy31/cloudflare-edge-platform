mock_provider "cloudflare" {}

variables {
  zone_id = "0123456789abcdef0123456789abcdef"
  name    = "test"
}

run "rejects_unknown_action" {
  command = plan
  variables {
    custom_rules = [{ ref = "x", description = "x", action = "log", expression = "true" }]
  }
  expect_failures = [cloudflare_ruleset.custom]
}

run "rejects_duplicate_refs" {
  command = plan
  variables {
    custom_rules = [
      { ref = "x", description = "a", action = "block", expression = "true" },
      { ref = "x", description = "b", action = "block", expression = "true" },
    ]
  }
  expect_failures = [cloudflare_ruleset.custom]
}

run "multiline_expressions_are_flattened" {
  command = plan
  variables {
    custom_rules = [{ ref = "x", description = "x", action = "block", expression = "a\nor b\n" }]
  }
  assert {
    condition     = cloudflare_ruleset.custom.rules[0].expression == "a or b"
    error_message = "YAML folded expressions must become a single line."
  }
}

# Zone-wide security and TLS settings. Each setting is its own resource so a
# change shows up in the plan as exactly one line, and drift is easy to spot.

locals {
  # Simple on/off and string settings.
  settings = {
    ssl                      = "strict" # origin certificate must be valid
    min_tls_version          = var.min_tls_version
    tls_1_3                  = "on"
    always_use_https         = "on"
    automatic_https_rewrites = "on"
    opportunistic_encryption = "on"
    http3                    = "on"
    "0rtt"                   = "off" # 0-RTT allows request replay; not worth it for APIs
    browser_check            = "on"
    security_level           = var.security_level
    email_obfuscation        = "on"
  }
}

resource "cloudflare_zone_setting" "this" {
  for_each = local.settings

  zone_id    = var.zone_id
  setting_id = each.key
  value      = each.value
}

resource "cloudflare_zone_setting" "hsts" {
  zone_id    = var.zone_id
  setting_id = "security_header"
  value = {
    strict_transport_security = {
      enabled            = var.hsts.enabled
      max_age            = var.hsts.max_age
      include_subdomains = var.hsts.include_subdomains
      preload            = var.hsts.preload
      nosniff            = true
    }
  }
}

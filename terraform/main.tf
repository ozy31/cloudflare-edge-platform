locals {
  name = "edge-${var.environment}"
}

module "zone_baseline" {
  source = "./modules/zone-baseline"

  zone_id        = var.zone_id
  security_level = var.environment == "prod" ? "medium" : "low"
}

module "dns" {
  source = "./modules/dns"

  zone_id    = var.zone_id
  records    = var.dns_records
  sends_mail = var.sends_mail
}

module "waf" {
  source = "./modules/waf"

  zone_id          = var.zone_id
  name             = local.name
  custom_rules     = yamldecode(file("${path.module}/../policies/waf-custom-rules.yaml"))
  managed_rulesets = var.managed_rulesets
}

module "rate_limits" {
  source = "./modules/rate-limits"

  zone_id   = var.zone_id
  name      = local.name
  rules     = yamldecode(file("${path.module}/../policies/rate-limits.yaml"))
  max_rules = var.rate_limit_max_rules
}

module "turnstile" {
  source = "./modules/turnstile"
  count  = length(var.turnstile_domains) > 0 ? 1 : 0

  account_id = var.account_id
  name       = "${local.name}-login"
  domains    = var.turnstile_domains
}

module "cache_headers" {
  source = "./modules/cache-headers"

  zone_id = var.zone_id
  name    = local.name
}

module "tunnel" {
  source = "./modules/tunnel"
  count  = length(var.tunnel_routes) > 0 ? 1 : 0

  account_id = var.account_id
  zone_id    = var.zone_id
  name       = local.name
  routes     = var.tunnel_routes
}

module "access" {
  source = "./modules/access"
  count  = length(var.access.applications) > 0 ? 1 : 0

  account_id            = var.account_id
  name                  = local.name
  applications          = var.access.applications
  allowed_email_domains = var.access.allowed_email_domains
  allowed_emails        = var.access.allowed_emails
  require_mfa           = var.access.require_mfa
  service_tokens        = var.access.service_tokens
}

module "logpush" {
  source = "./modules/logpush"
  count  = var.logpush.enabled ? 1 : 0

  account_id           = var.account_id
  zone_id              = var.zone_id
  name                 = local.name
  bucket_name          = var.logpush.bucket_name
  retention_days       = var.logpush.retention_days
  sample_rate          = var.logpush.sample_rate
  only_security_events = var.logpush.only_security_events
  r2_access_key_id     = var.r2_access_key_id
  r2_secret_access_key = var.r2_secret_access_key
}

module "notifications" {
  source = "./modules/notifications"
  count  = length(var.alert_emails) > 0 ? 1 : 0

  account_id  = var.account_id
  zone_id     = var.zone_id
  name        = local.name
  emails      = var.alert_emails
  webhook_url = var.alert_webhook_url
}

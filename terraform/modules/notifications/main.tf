# Cloudflare notifications for the edge incidents that need a human. Each
# alert links to its runbook in docs/runbooks/. Delivery is by email and,
# optionally, a webhook (Slack, PagerDuty, ...); the webhook URL is a
# sensitive input and never stored in the repository.

locals {
  alerts = {
    ddos_l7 = {
      type        = "dos_attack_l7"
      description = "HTTP DDoS attack mitigated. Runbook: docs/runbooks/ddos.md"
      zone_filter = true
    }
    tunnel_health = {
      type        = "tunnel_health_event"
      description = "Cloudflare Tunnel degraded or down. Runbook: docs/runbooks/tunnel-down.md"
      zone_filter = false
    }
    origin_errors = {
      type        = "real_origin_monitoring"
      description = "Origin unreachable from Cloudflare. Runbook: docs/runbooks/origin-errors.md"
      zone_filter = true
    }
    logpush_failing = {
      type        = "failing_logpush_job_disabled_alert"
      description = "Logpush job failing or disabled; edge logs are not being collected"
      zone_filter = false
    }
    service_token_expiry = {
      type        = "expiring_service_token_alert"
      description = "An Access service token expires soon; rotate it. Runbook: docs/runbooks/access-service-token.md"
      zone_filter = false
    }
    certificate = {
      type        = "universal_ssl_event_type"
      description = "Edge certificate issuance or renewal event"
      zone_filter = true
    }
  }

  enabled_alerts = { for k, v in local.alerts : k => v if contains(var.alerts, k) }
}

resource "cloudflare_notification_policy_webhooks" "this" {
  count = var.webhook_url == null ? 0 : 1

  account_id = var.account_id
  name       = "${var.name}-oncall"
  url        = var.webhook_url
}

resource "cloudflare_notification_policy" "this" {
  for_each = local.enabled_alerts

  account_id  = var.account_id
  name        = "${var.name}-${each.key}"
  description = each.value.description
  alert_type  = each.value.type
  enabled     = true

  mechanisms = {
    email    = [for e in var.emails : { id = e }]
    webhooks = var.webhook_url == null ? null : [{ id = cloudflare_notification_policy_webhooks.this[0].id }]
  }

  filters = each.value.zone_filter ? { zones = [var.zone_id] } : null
}

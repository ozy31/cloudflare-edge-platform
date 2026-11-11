# Cloudflare Access puts internal tools (Argo CD, Grafana, ...) behind SSO
# at the edge. Requests without a valid Access session never reach the
# tunnel, so these tools need no VPN and no public login page of their own.

resource "cloudflare_zero_trust_access_policy" "staff" {
  account_id       = var.account_id
  name             = "${var.name}-staff"
  decision         = "allow"
  session_duration = var.session_duration

  include = concat(
    [for d in var.allowed_email_domains : { email_domain = { domain = d } }],
    [for e in var.allowed_emails : { email = { email = e } }],
  )

  # Everyone must also have used MFA at their identity provider.
  require = var.require_mfa ? [{ auth_method = { auth_method = "mfa" } }] : []
}

# Machine access (CI, uptime checks) uses service tokens, never a person's
# session.
resource "cloudflare_zero_trust_access_service_token" "machine" {
  for_each = toset(var.service_tokens)

  account_id = var.account_id
  name       = "${var.name}-${each.key}"
  duration   = "8760h"
}

resource "cloudflare_zero_trust_access_policy" "machine" {
  count = length(var.service_tokens) > 0 ? 1 : 0

  account_id = var.account_id
  name       = "${var.name}-machines"
  decision   = "non_identity"

  include = [
    for t in cloudflare_zero_trust_access_service_token.machine : { service_token = { token_id = t.id } }
  ]
}

resource "cloudflare_zero_trust_access_application" "app" {
  for_each = { for a in var.applications : a.name => a }

  account_id                 = var.account_id
  name                       = "${var.name}-${each.key}"
  domain                     = each.value.hostname
  type                       = "self_hosted"
  session_duration           = var.session_duration
  auto_redirect_to_identity  = true
  app_launcher_visible       = true
  http_only_cookie_attribute = true
  same_site_cookie_attribute = "lax"

  policies = concat(
    [{ id = cloudflare_zero_trust_access_policy.staff.id, precedence = 1 }],
    each.value.allow_machines && length(var.service_tokens) > 0 ? [{ id = cloudflare_zero_trust_access_policy.machine[0].id, precedence = 2 }] : [],
  )
}

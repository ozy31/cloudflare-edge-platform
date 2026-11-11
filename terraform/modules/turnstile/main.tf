# Turnstile replaces CAPTCHAs on forms (login, sign-up). The site key is
# public; the secret key is read by the application from its secret store
# and is never output by this module.
resource "cloudflare_turnstile_widget" "this" {
  account_id = var.account_id
  name       = var.name
  domains    = var.domains
  mode       = var.mode
  region     = "world"
}

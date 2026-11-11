output "sitekey" {
  description = "Public site key to embed in the login and sign-up pages."
  value       = cloudflare_turnstile_widget.this.sitekey
}

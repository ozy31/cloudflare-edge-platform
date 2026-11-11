# Cache rules: never cache API or authenticated traffic, cache static
# assets hard. Response header rules: add browser security headers and
# remove headers that reveal the origin stack.

resource "cloudflare_ruleset" "cache" {
  zone_id     = var.zone_id
  name        = "${var.name}-cache"
  description = "Cache rules"
  kind        = "zone"
  phase       = "http_request_cache_settings"

  rules = [
    {
      ref         = "bypass_api_and_auth"
      description = "API responses and anything with a session cookie are never cached"
      expression  = "starts_with(http.request.uri.path, \"/api/\") or http.cookie contains \"session\""
      action      = "set_cache_settings"
      enabled     = true
      action_parameters = {
        cache = false
      }
    },
    {
      ref         = "cache_static_assets"
      description = "Fingerprinted static assets"
      expression  = "http.request.uri.path.extension in {${join(" ", [for e in var.static_extensions : "\"${e}\""])}}"
      action      = "set_cache_settings"
      enabled     = true
      action_parameters = {
        cache = true
        edge_ttl = {
          mode    = "override_origin"
          default = var.static_edge_ttl
        }
        browser_ttl = {
          mode    = "override_origin"
          default = var.static_browser_ttl
        }
      }
    },
  ]
}

resource "cloudflare_ruleset" "response_headers" {
  zone_id     = var.zone_id
  name        = "${var.name}-security-headers"
  description = "Browser security headers"
  kind        = "zone"
  phase       = "http_response_headers_transform"

  rules = [
    {
      ref         = "security_headers"
      description = "Add security headers, remove stack fingerprints"
      expression  = "true"
      action      = "rewrite"
      enabled     = true
      action_parameters = {
        headers = merge(
          { for k, v in var.security_headers : k => { operation = "set", value = v } },
          { for h in var.remove_headers : h => { operation = "remove" } },
        )
      }
    },
  ]
}

variable "zone_id" {
  description = "Zone the rules apply to."
  type        = string
}

variable "name" {
  description = "Name prefix for the rulesets."
  type        = string
}

variable "static_extensions" {
  description = "File extensions treated as cacheable static assets."
  type        = list(string)
  default     = ["js", "css", "woff2", "png", "jpg", "jpeg", "webp", "avif", "svg", "ico"]
}

variable "static_edge_ttl" {
  description = "Edge cache TTL for static assets, in seconds."
  type        = number
  default     = 2592000 # 30 days; assets are fingerprinted, so a deploy changes the URL
}

variable "static_browser_ttl" {
  description = "Browser cache TTL for static assets, in seconds."
  type        = number
  default     = 86400
}

variable "security_headers" {
  description = "Response headers to set on every response."
  type        = map(string)
  default = {
    "X-Content-Type-Options" = "nosniff"
    "X-Frame-Options"        = "DENY"
    "Referrer-Policy"        = "strict-origin-when-cross-origin"
    "Permissions-Policy"     = "camera=(), microphone=(), geolocation=(), payment=()"
  }
}

variable "remove_headers" {
  description = "Response headers to strip (they reveal the origin stack)."
  type        = list(string)
  default     = ["X-Powered-By", "Server-Timing", "X-AspNet-Version"]
}

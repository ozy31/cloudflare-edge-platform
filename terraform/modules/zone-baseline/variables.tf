variable "zone_id" {
  description = "Zone the settings apply to."
  type        = string
}

variable "min_tls_version" {
  description = "Lowest TLS version clients may use."
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.2", "1.3"], var.min_tls_version)
    error_message = "min_tls_version must be 1.2 or 1.3; older versions are not allowed."
  }
}

variable "security_level" {
  description = "Cloudflare security level (challenge threshold for IP reputation)."
  type        = string
  default     = "medium"

  validation {
    condition     = contains(["essentially_off", "low", "medium", "high", "under_attack"], var.security_level)
    error_message = "security_level must be one of essentially_off, low, medium, high, under_attack."
  }
}

variable "hsts" {
  description = "HTTP Strict Transport Security settings."
  type = object({
    enabled            = bool
    max_age            = number
    include_subdomains = bool
    preload            = bool
  })
  default = {
    enabled            = true
    max_age            = 31536000
    include_subdomains = true
    preload            = false # preload is hard to undo; opt in deliberately
  }

  validation {
    condition     = !var.hsts.enabled || var.hsts.max_age >= 15552000
    error_message = "With HSTS enabled, max_age must be at least 180 days (15552000 s)."
  }
}

variable "account_id" {
  description = "Cloudflare account ID (Turnstile, Tunnel, Access, Logpush are account-level)."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32-character hex Cloudflare account ID."
  }
}

variable "zone_id" {
  description = "Cloudflare zone ID of the domain this platform fronts."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32-character hex Cloudflare zone ID."
  }
}

variable "zone_name" {
  description = "Apex domain of the zone, for example example.com."
  type        = string
}

variable "environment" {
  description = "Environment name, used in resource names and descriptions."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "rate_limit_max_rules" {
  description = "Rate limiting rules allowed by the zone plan."
  type        = number
  default     = 2
}

variable "turnstile_domains" {
  description = "Hostnames that embed the Turnstile widget (login, sign-up)."
  type        = list(string)
  default     = []
}

variable "tunnel_routes" {
  description = "Hostnames served through Cloudflare Tunnel and their in-cluster services."
  type = list(object({
    hostname     = string
    service      = string
    http2_origin = optional(bool, false)
  }))
  default = []
}

variable "access" {
  description = "Cloudflare Access for internal tools. Leave applications empty to skip."
  type = object({
    applications = optional(list(object({
      name           = string
      hostname       = string
      allow_machines = optional(bool, false)
    })), [])
    allowed_email_domains = optional(list(string), [])
    allowed_emails        = optional(list(string), [])
    require_mfa           = optional(bool, true)
    service_tokens        = optional(list(string), [])
  })
  default = {}

  validation {
    condition     = length(var.access.applications) == 0 || length(var.access.allowed_email_domains) + length(var.access.allowed_emails) > 0
    error_message = "Access applications need at least one allowed email domain or email, otherwise nobody can get in."
  }
}

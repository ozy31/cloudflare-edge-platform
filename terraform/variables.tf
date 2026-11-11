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

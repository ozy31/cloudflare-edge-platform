variable "account_id" {
  description = "Account that owns the Access applications."
  type        = string
}

variable "name" {
  description = "Name prefix."
  type        = string
}

variable "applications" {
  description = "Internal tools to protect. allow_machines lets service tokens in as well."
  type = list(object({
    name           = string
    hostname       = string
    allow_machines = optional(bool, false)
  }))
}

variable "allowed_email_domains" {
  description = "Identity-provider email domains allowed in."
  type        = list(string)
  default     = []
}

variable "allowed_emails" {
  description = "Individual emails allowed in (contractors, break-glass)."
  type        = list(string)
  default     = []
}

variable "require_mfa" {
  description = "Require that the identity provider login used MFA."
  type        = bool
  default     = true
}

variable "session_duration" {
  description = "How long an Access session lasts."
  type        = string
  default     = "8h"
}

variable "service_tokens" {
  description = "Names of machine clients that get a service token (e.g. ci, uptime)."
  type        = list(string)
  default     = []
}

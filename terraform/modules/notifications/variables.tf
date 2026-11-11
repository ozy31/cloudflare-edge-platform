variable "account_id" {
  description = "Account the notifications belong to."
  type        = string
}

variable "zone_id" {
  description = "Zone used to filter zone-level alerts."
  type        = string
}

variable "name" {
  description = "Name prefix."
  type        = string
}

variable "alerts" {
  description = "Alerts to enable (ddos_l7, tunnel_health, origin_errors, logpush_failing, service_token_expiry, certificate). Some need a paid plan."
  type        = list(string)
  default     = ["ddos_l7", "tunnel_health", "origin_errors", "logpush_failing", "service_token_expiry", "certificate"]

  validation {
    condition     = alltrue([for a in var.alerts : contains(["ddos_l7", "tunnel_health", "origin_errors", "logpush_failing", "service_token_expiry", "certificate"], a)])
    error_message = "Unknown alert name."
  }
}

variable "emails" {
  description = "Email recipients (a team list, not individuals)."
  type        = list(string)

  validation {
    condition     = length(var.emails) > 0
    error_message = "At least one email recipient is required."
  }
}

variable "webhook_url" {
  description = "Optional on-call webhook (Slack, PagerDuty, ...). Pass via TF_VAR_alert_webhook_url."
  type        = string
  default     = null
  sensitive   = true
}

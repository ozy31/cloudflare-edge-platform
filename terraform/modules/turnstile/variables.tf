variable "account_id" {
  description = "Account that owns the widget."
  type        = string
}

variable "name" {
  description = "Widget name."
  type        = string
}

variable "domains" {
  description = "Hostnames the widget may be embedded on."
  type        = list(string)
}

variable "mode" {
  description = "managed (Cloudflare decides when to show a challenge), non-interactive or invisible."
  type        = string
  default     = "managed"

  validation {
    condition     = contains(["managed", "non-interactive", "invisible"], var.mode)
    error_message = "mode must be managed, non-interactive or invisible."
  }
}

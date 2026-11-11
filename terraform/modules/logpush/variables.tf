variable "account_id" {
  description = "Account that owns the R2 bucket."
  type        = string
}

variable "zone_id" {
  description = "Zone whose HTTP request logs are pushed."
  type        = string
}

variable "name" {
  description = "Name prefix."
  type        = string
}

variable "bucket_name" {
  description = "R2 bucket for the logs."
  type        = string
}

variable "bucket_location" {
  description = "R2 location hint (weur keeps EU traffic logs in western Europe)."
  type        = string
  default     = "weur"
}

variable "retention_days" {
  description = "Days before log objects are deleted."
  type        = number
  default     = 30

  validation {
    condition     = var.retention_days >= 7 && var.retention_days <= 365
    error_message = "retention_days must be between 7 and 365."
  }
}

variable "r2_access_key_id" {
  description = "R2 API token access key ID used by Logpush to write. Pass via TF_VAR_r2_access_key_id."
  type        = string
  sensitive   = true
}

variable "r2_secret_access_key" {
  description = "R2 API token secret used by Logpush to write. Pass via TF_VAR_r2_secret_access_key."
  type        = string
  sensitive   = true
}

variable "sample_rate" {
  description = "Fraction of requests to push (1 = all)."
  type        = number
  default     = 1

  validation {
    condition     = var.sample_rate > 0 && var.sample_rate <= 1
    error_message = "sample_rate must be in (0, 1]."
  }
}

variable "only_security_events" {
  description = "Push only requests where a security rule acted (cheaper, but no baseline traffic)."
  type        = bool
  default     = false
}

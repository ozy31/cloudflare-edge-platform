variable "zone_id" {
  description = "Zone the rate limits apply to."
  type        = string
}

variable "name" {
  description = "Name prefix for the ruleset."
  type        = string
}

variable "rules" {
  description = "Rate limiting rules, usually yamldecode(file(\"policies/rate-limits.yaml\"))."
  type        = any
}

variable "max_rules" {
  description = "Rate limiting rules allowed on the zone plan (free 1, pro 2, business 5)."
  type        = number
  default     = 2
}

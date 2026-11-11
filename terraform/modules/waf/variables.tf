variable "zone_id" {
  description = "Zone the WAF applies to."
  type        = string
}

variable "name" {
  description = "Name prefix for the rulesets."
  type        = string
}

variable "custom_rules" {
  description = "Custom rules, usually yamldecode(file(\"policies/waf-custom-rules.yaml\"))."
  type        = any
}

variable "managed_rulesets" {
  description = "Managed rulesets to execute, in order."
  type = list(object({
    ref         = string
    id          = string
    action      = optional(string)
    sensitivity = optional(string)
  }))
  default = []
}

variable "managed_rulesets" {
  description = <<-EOT
    Managed WAF rulesets to execute. Defaults to the Cloudflare Managed
    Ruleset and the OWASP core ruleset (Pro plan and above). On a free zone
    use the free managed ruleset instead.
  EOT
  type = list(object({
    ref         = string
    id          = string
    action      = optional(string)
    sensitivity = optional(string)
  }))
  default = [
    { ref = "cloudflare_managed", id = "efb7b92c949f41869f9e9ef4f2c3d1fe" },
    { ref = "owasp_core", id = "4814384a9e5d4991b9815dcfc25d2f1f", action = "managed_challenge", sensitivity = "medium" },
  ]
}

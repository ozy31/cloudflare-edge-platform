variable "dns_records" {
  description = "Application DNS records (see modules/dns). Tunnel-backed hostnames are added by the tunnel module."
  type = map(object({
    name    = string
    type    = string
    content = string
    proxied = optional(bool, true)
    ttl     = optional(number, 300)
    comment = optional(string)
  }))
  default = {}
}

variable "sends_mail" {
  description = "Whether the zone sends email."
  type        = bool
  default     = false
}

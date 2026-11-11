variable "zone_id" {
  description = "Zone the records belong to."
  type        = string
}

variable "records" {
  description = "Application DNS records, keyed by a stable name."
  type = map(object({
    name    = string
    type    = string
    content = string
    proxied = optional(bool, true)
    ttl     = optional(number, 300)
    comment = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.records) : contains(["A", "AAAA", "CNAME", "TXT", "MX"], r.type)])
    error_message = "Only A, AAAA, CNAME, TXT and MX records are managed here."
  }

  # An unproxied A/AAAA record publishes the origin IP and bypasses the WAF.
  # Allow it only when the record says why.
  validation {
    condition = alltrue([
      for r in values(var.records) :
      r.proxied || !contains(["A", "AAAA"], r.type) || r.comment != null
    ])
    error_message = "Unproxied A/AAAA records expose the origin; add a comment explaining why."
  }
}

variable "caa_issuers" {
  description = "Certificate authorities allowed to issue for the zone."
  type        = list(string)
  default     = ["letsencrypt.org", "pki.goog", "digicert.com", "ssl.com"]
}

variable "caa_report_email" {
  description = "Where CAs should report rejected issuance requests (optional)."
  type        = string
  default     = null
}

variable "sends_mail" {
  description = "Set to true if the zone sends email; disables the null SPF and reject DMARC records."
  type        = bool
  default     = false
}

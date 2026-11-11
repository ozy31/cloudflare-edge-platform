variable "account_id" {
  description = "Account that owns the tunnel."
  type        = string
}

variable "zone_id" {
  description = "Zone for the tunnel hostnames."
  type        = string
}

variable "name" {
  description = "Tunnel name."
  type        = string
}

variable "routes" {
  description = "Public hostnames and the in-cluster service each one reaches."
  type = list(object({
    hostname     = string
    service      = string # e.g. http://web.app.svc.cluster.local:80
    http2_origin = optional(bool, false)
  }))

  validation {
    condition     = alltrue([for r in var.routes : can(regex("^https?://[a-z0-9.-]+\\.svc\\.cluster\\.local(:[0-9]+)?$", r.service))])
    error_message = "Tunnel routes must point at in-cluster services (http(s)://<svc>.<ns>.svc.cluster.local[:port])."
  }

  validation {
    condition     = length(distinct([for r in var.routes : r.hostname])) == length(var.routes)
    error_message = "Each hostname can only be routed once."
  }
}

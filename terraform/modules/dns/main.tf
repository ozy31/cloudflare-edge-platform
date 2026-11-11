# DNS for the zone: application records plus the records that stop the
# domain being abused (CAA limits who can issue certificates; SPF/DMARC say
# "this domain sends no mail" unless mail is explicitly enabled).

resource "cloudflare_dns_record" "app" {
  for_each = var.records

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  proxied = each.value.proxied
  ttl     = each.value.proxied ? 1 : each.value.ttl # 1 = automatic, required when proxied
  comment = coalesce(each.value.comment, "managed by terraform")
}

resource "cloudflare_dns_record" "caa" {
  for_each = toset(var.caa_issuers)

  zone_id = var.zone_id
  name    = "@"
  type    = "CAA"
  ttl     = 3600
  data = {
    flags = 0
    tag   = "issue"
    value = each.value
  }
  comment = "only these CAs may issue certificates"
}

resource "cloudflare_dns_record" "caa_iodef" {
  count = var.caa_report_email == null ? 0 : 1

  zone_id = var.zone_id
  name    = "@"
  type    = "CAA"
  ttl     = 3600
  data = {
    flags = 0
    tag   = "iodef"
    value = "mailto:${var.caa_report_email}"
  }
}

# Domains that send no mail still get spoofed. A strict SPF and DMARC policy
# makes receivers reject it.
resource "cloudflare_dns_record" "spf_null" {
  count = var.sends_mail ? 0 : 1

  zone_id = var.zone_id
  name    = "@"
  type    = "TXT"
  ttl     = 3600
  content = "\"v=spf1 -all\""
  comment = "domain sends no mail"
}

resource "cloudflare_dns_record" "dmarc_reject" {
  count = var.sends_mail ? 0 : 1

  zone_id = var.zone_id
  name    = "_dmarc"
  type    = "TXT"
  ttl     = 3600
  content = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s\""
  comment = "reject spoofed mail"
}

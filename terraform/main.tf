locals {
  name = "edge-${var.environment}"
}

module "zone_baseline" {
  source = "./modules/zone-baseline"

  zone_id        = var.zone_id
  security_level = var.environment == "prod" ? "medium" : "low"
}

module "dns" {
  source = "./modules/dns"

  zone_id    = var.zone_id
  records    = var.dns_records
  sends_mail = var.sends_mail
}

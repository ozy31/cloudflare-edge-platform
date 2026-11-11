# HTTP request logs pushed to an R2 bucket as NDJSON, one folder per day.
# R2 has no egress fees, so the logs can be queried in place (DuckDB,
# ClickHouse) or copied to a SIEM. Only the fields the analysis needs are
# pushed; client IPs are kept for abuse analysis and expire with the bucket
# lifecycle rule.

locals {
  fields = [
    "RayID", "EdgeStartTimestamp", "ClientIP", "ClientCountry", "ClientRequestHost",
    "ClientRequestMethod", "ClientRequestPath", "ClientRequestUserAgent",
    "EdgeResponseStatus", "OriginResponseStatus", "OriginResponseDurationMs",
    "EdgeTimeToFirstByteMs", "CacheCacheStatus", "SecurityAction",
    "SecurityRuleID", "SecurityRuleDescription", "BotScore", "WAFAttackScore",
  ]
}

resource "cloudflare_r2_bucket" "logs" {
  account_id = var.account_id
  name       = var.bucket_name
  location   = var.bucket_location
}

resource "cloudflare_r2_bucket_lifecycle" "logs" {
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.logs.name

  rules = [{
    id         = "expire-logs"
    enabled    = true
    conditions = { prefix = "" }
    delete_objects_transition = {
      condition = {
        type    = "Age"
        max_age = var.retention_days * 86400
      }
    }
  }]
}

resource "cloudflare_logpush_job" "http_requests" {
  zone_id          = var.zone_id
  name             = "${var.name}-http-requests"
  dataset          = "http_requests"
  enabled          = true
  destination_conf = "r2://${cloudflare_r2_bucket.logs.name}/http_requests/{DATE}?account-id=${var.account_id}&access-key-id=${var.r2_access_key_id}&secret-access-key=${var.r2_secret_access_key}"
  filter           = var.only_security_events ? jsonencode({ where = { key = "SecurityAction", operator = "neq", value = "" } }) : null

  output_options = {
    field_names      = local.fields
    output_type      = "ndjson"
    timestamp_format = "rfc3339"
    sample_rate      = var.sample_rate
  }
}

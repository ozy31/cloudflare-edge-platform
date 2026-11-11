output "bucket" {
  description = "R2 bucket holding the logs."
  value       = cloudflare_r2_bucket.logs.name
}

output "fields" {
  description = "Fields pushed for each request."
  value       = local.fields
}

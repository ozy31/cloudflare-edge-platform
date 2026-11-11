output "security_headers" {
  description = "Headers set on every response."
  value       = keys(var.security_headers)
}

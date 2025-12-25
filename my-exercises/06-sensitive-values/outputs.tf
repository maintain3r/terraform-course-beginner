output "additional_tags" {
  value       = local.common_tags
  description = "Output additional tags"
}

output "api_token_output" {
  value       = local.security_api_token
  description = "API token used to access data platform"
  sensitive   = true
}

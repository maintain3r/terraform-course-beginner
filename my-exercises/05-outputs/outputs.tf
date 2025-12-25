output "additional_tags" {
  value       = merge(local.common_tags, var.additional_tags)
  description = "Output additional tags"
}

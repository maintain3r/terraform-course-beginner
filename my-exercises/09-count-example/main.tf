resource "random_id" "mixer" {
  count       = length(var.mixer_configs)
  byte_length = var.mixer_configs[count.index].byte_length
  prefix      = var.mixer_configs[count.index].prefix
}

output "mixers_created_total" {
  value       = length(random_id.mixer)
  description = "Returns total amount of mixers created"
}

output "mixers_created_by_prefix" {
  value       = random_id.mixer[*].prefix
  description = "Returns mixers created by prefix name"
}

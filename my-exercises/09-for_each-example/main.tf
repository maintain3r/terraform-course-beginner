resource "random_id" "all_mixer_resource" {
  # each.key - represents the key name of the map
  # each.value - represents the value the the key is equoal to 
  for_each    = var.mixer_config_tiers
  byte_length = each.value.byte_length
  prefix      = each.value.prefix
}

resource "random_id" "golden_tier_mixer" {
  byte_length = var.mixer_config_tiers["golden"].byte_length
  prefix      = var.mixer_config_tiers["golden"].prefix
}

output "list_mixer_resources" {
  value = { for key, value in random_id.all_mixer_resource  : key=>value.prefix }
}

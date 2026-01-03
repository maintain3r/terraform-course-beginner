resource "random_id" "users_for_each_method" {
  # use toset() function to get rid of duplicate items
  for_each = toset(local.users_from_yaml[*].username)
  prefix   = each.value
  byte_length = 3
}

resource "random_id" "users_count_method" {
  count = length(local.users_from_yaml)
  prefix   = local.users_from_yaml[count.index].username
  byte_length = 3
}


resource "random_id" "users_map_for_each_method" {
  for_each = local.users_map
  prefix   = each.key
  byte_length = 3
}

locals {
  lst = ["katakata","perpey","kutsi-kutsi"]
}

output "to_set" {
  value = toset(local.users_from_yaml[*].username)
}

resource "random_id" "process_list_variable_with_for_each" {
  for_each = toset(local.lst)
  byte_length = 2
  prefix = "VALUE: ${each.value} and KEY ${each.key}"
}


locals {
  # loads value of key users, which is a list of maps containing 2 keys - username and roles
  users_from_yaml = yamldecode(file("${path.module}/user-roles.yaml")).users

  # creates a map where key is username and value is a list of roles
  users_map = {
    for item in local.users_from_yaml : item.username => item.roles
  }
}

output "users_from_yaml" {
  value = local.users_from_yaml
  description = "content of user-roles.yaml.users"
}

output "users_map" {
  value = local.users_map
  description = "A map containing username = > [roles]"
}

output "referencing_resource_using_for_each" {
  value = { for key, value in random_id.users_map_for_each_method : "resource_key_${key}" => value.hex  }
}

output "referecing_single_mixer_resource_by_key" {
  value = random_id.users_map_for_each_method["john"].dec
}

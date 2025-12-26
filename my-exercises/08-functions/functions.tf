
locals {
  name = "Perpey"
  age  = 10
  my_object = {
    key1 = 10
    key2 = "my_value"
  }
}

output "upper_case" {
  value = upper(local.name)
}

output "starts_with" {
  value = startswith(lower(local.name), "perp")
}

output "num_power_of" {
  value = pow(local.age, 4)
}

# read users.yaml config, decode it access all name values of a list type variable `users`
output "yaml_config" {
  value = yamldecode(file("${path.module}/users.yaml")).users[*].name
}

output "locals_to_json" {
  value = jsonencode(local.my_object)
}

output "locals_to_yaml" {
  value = yamlencode(local.my_object)
}


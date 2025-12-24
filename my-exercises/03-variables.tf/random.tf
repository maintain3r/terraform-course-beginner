resource "random_id" "ec2_web_server" {
  byte_length = 8
}

output "ec2_web_server" {
  value = "You've deployed an ec2 instance of type ${var.aws_ec2_volume_config.type} with ${var.aws_ec2_volume_config.size}GB of root volme."
}

output "map_of_strings" {
  value = var.map_of_string.key1
}

output "simple_map" {
  value = var.simple_map.name
}

output "simple_map_full_map" {
  value = var.simple_map
}

output "list_of_objects_element_0_name" {
  value = var.list_of_objects[0].name
}

output "list_of_objects_element_0_age" {
  value = var.list_of_objects[0].age
}

# maps[*] is a special experssion called Splat expression
# it allows getting all specific element key values regardless of index number
# in this case `var.list_of_maps` is a list of maps and we get only the `name` fields
output "list_of_objects_all_elements_name" {
  value = var.list_of_objects[*].name
}

# list of maps
output "list_of_maps_element_1" {
  value = var.list_of_maps[1].region
}

# referencing same variable but extracting all regions using terraform Splat expression
output "list_of_maps_region_fields" {
  value = var.list_of_maps[*].region
}

# printing all list_of_maps variable content
output "list_of_maps_all_fields" {
  value = var.list_of_maps
}

# here we use TF `merge` function that allows merging 2 maps into a single one
output "additional_tags" {
  value = merge(var.additional_tags, {
    ManagedBy = "Terraform"
  })
}

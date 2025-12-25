resource "random_id" "dummy" {
  byte_length = var.random_byte_length
}

output "ec2_web_server" {
  value = "You've deployed an ec2 instance of type ${local.ec2_instance_type} with ${local.ec2_volume_config.type} root volume of size ${local.ec2_volume_config.size}GB."
}

output "additional_tags" {
  value = merge(local.common_tags, var.additional_tags)
}

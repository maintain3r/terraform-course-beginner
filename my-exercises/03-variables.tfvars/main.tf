resource "random_id" "dummy" {
  byte_length = var.random_byte_length
}

output "ec2_web_server" {
  value = "You've deployed an ec2 instance of type ${var.ec2_instance_type} with ${var.ec2_volume_config.type} root volume of size ${var.ec2_volume_config.size}GB."
}

output "additional_tags" {
  value = var.additional_tags
}

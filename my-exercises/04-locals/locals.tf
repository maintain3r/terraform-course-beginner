locals {
  ec2_instance_type = var.ec2_instance_type
}

locals {
  ec2_volume_config = var.ec2_volume_config
}

locals {
  common_tags = {
    service  = "Infra"
    provider = "AWS"
    bu       = "Coveo"
  }
}

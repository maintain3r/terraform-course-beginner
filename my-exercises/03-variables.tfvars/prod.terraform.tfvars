# TF loads automatically terraform.tfvars file, any other *.tfvars file should be passed to TF in cmd argument
# TF loads automatically *.auto.tfvars files, e.g. prod.auto.tfvars, prod.teraform.auto.tfvars; the file name should end with *.auto.tfvars

random_byte_length = 10
ec2_instance_type = "m3.large"

ec2_volume_config = {
  size = 50
  type = "gp3"
}

additional_tags = {
  ValuesFrom  = "prod.terraform.tfvars"
  Environment = "prod"
}

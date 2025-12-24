# TF loads automatically terraform.tfvars file
# TF loads automatically *.auto.tfvars files, e.g. dev.auto.tfvars, dev.teraform.auto.tfvars; the file name should end with *.auto.tfvars

random_byte_length = 5
ec2_instance_type = "t2.micro"

ec2_volume_config = {
  size = 10
  type = "gp2"
}

additional_tags = {
  ValuesFrom  = "dev.terraform.tfvars"
  Environment = "dev"
}

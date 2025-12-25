# TF loads automatically terraform.tfvars file, any other *.tfvars file should be passed to TF in cmd argument
# TF loads automatically *.auto.tfvars files, e.g. prod.auto.tfvars, prod.teraform.auto.tfvars; the file name should end with *.auto.tfvars and it's more preferred that terraform.tfvars
# For more info on variable precedence order read here ../../08-input-vars-locals-outputs/README.md

random_byte_length = 1
ec2_instance_type = "t2.micro"

ec2_volume_config = {
  size = 10
  type = "gp2"
}

additional_tags = {
  ValuesFrom  = "terraform.tfvars"
}

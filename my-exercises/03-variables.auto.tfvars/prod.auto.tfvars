# TF loads automatically terraform.tfvars file, any other *.tfvars file should be passed to TF in cmd argument
# TF loads automatically *.auto.tfvars files, e.g. prod.auto.tfvars, prod.teraform.auto.tfvars; the file name should end with *.auto.tfvars and it's more preferred that terraform.tfvars
# For more info on variable precedence order read here ../../08-input-vars-locals-outputs/README.md

random_byte_length = 123
ec2_instance_type = "t3.large"

ec2_volume_config = {
  size = 10
  type = "gp3"
}

additional_tags = {
  ValuesFrom  = "prod.auto.tfvars"
}

variable "ec2_instance_type" {
  type        = string
  description = "Set ec2 instance type to deploy"
}

variable "ec2_volume_config" {
  type = object({
    size = number
    type = string
    }
  )
}

# in this case all values for each tag must be strings
variable "additional_tags" {
  type        = map(string)
  description = "Set any additional tags"
  default = {
    DefaultTag = "SetByDefaultInVariableTfFile"
  }
}

variable "random_byte_length" {
  type        = number
  description = "This variable will be differently assigned in different environments to trigger a new random resource generation if it has a different value."
}

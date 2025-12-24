###################### This file contains variable definitions with their description, type, default value, etc.
###################### To pas a value to a variable use anyt method you like, e.g. env variable, *.auto.tfvars, *.tfvars, etc


# for an oject type variabel you should explicitly 
# define the data type of each key within the object 
variable "aws_ec2_volume_config" {
  type = object({
    size = number
    type = string
  })

  description = "Specify EC2 instance type"

  default = {
    size = 10
    type = "t2.micro"
  }
}

# read this as a map with key values of type string
# it means all values of keys should be string only
variable "map_of_string" {
  type = map(string)
  default = {
    key1 = "one"
    key2 = "two"
  }
  description = "A map with key values of type string only"
}

# read this as map that has key values of Any type
variable "simple_map" {
  type = map(any)
  default = {
    name = "Bob"
    age  = 65
  }
  description = "A simple map variable where key values are of different type"
}

# read this as a list where each element it in it an object
# you should also specify the type of each key of the object wrapped into the list  
variable "list_of_objects" {
  type = list(object({
    name = string
    age  = number
  }))

  default = [
    {
      name = "Rossey"
      age  = "65"
    },
    {
      name = "Alice"
      age  = "25"
    }
  ]
  description = "An example of variable of type list of maps"
}

# list of simple maps which is a simplified version of the previous variable
variable "list_of_maps" {
  type = list(map(any))
  default = [
    {
      region  = "CA"
      az      = 1
      is_main = true
    },
    {
      region  = "MD"
      az      = 2
      is_main = false
    }
  ]
}

# can be used for specifying ay arbitrary tags
# using example map(string) as above
# by defult it's empty but you can pas all tags when you run terraform
# to pass variable values from command prompt use the following example
# $ terraform apply -var='additional_tags={ Env="prod", Owner="infra", CostCenter="1234" }'
variable "additional_tags" {
  type    = map(string)
  default = {}
}

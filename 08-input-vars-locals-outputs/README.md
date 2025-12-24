### Input Variables
Used for:
- Customizing aspects of TF configurations and modules without having to alter the source code.
- It's convention to declare them inside of `variables.tf` file, and we use them via `var.<NAME>`
- When defining a variable, you can set the type, provide a description, give a default value, set `sensitive` to a boolean value, and provide validation rules.
- When you run terraform plan or apply and don't provide any values for the variables, it will ask yuo to provide the values for each of the variables.
  If you provide defaults, Terraform will not ask for these values.

### Variable precedence order Low -> High
- Default values
- Environment variables
- `terrafor.tfvars` fle
- `terraform.tfvars.json`
- `*.auto.tfvars` or `*.auto.tfvars.json`
- Command line `-var` and `-var-file`
  -var 'varame=value'
  -var-file=filename

###NOTE
TF does not automatically load some_name.tfvars file, for this you should pass the file explicitly using `-var-file` param in cli.
TF automatically loads variable values from `terraform.tfvars` file.




Here’s the syntax for declaring a variable in a `*.tf` file, usually it's named as `variables.tf`.
We define variable name and its config specifying its type, default value, description, validation, etc
But to pass a value to this variable we use all variations mentioned above.
```
variable "NAME" {
   [CONFIG ...]
}
```

The body of the variable declaration can contain the following optional parameters:
- `description`
     It’s always a good idea to use this parameter to document how a variable is used.
     Your teammates will be able to see this description not only while reading the code but also when running the plan or apply commands.

- `default`
     There are a number of ways to provide a value for the variable, including passing it in at the command line (using the `-var` option), 
     via a file (using the -var-file option), or via an environment variable (Terraform looks for environment variables of the name `TF_VAR_<variable_name>`). 
     If no value is passed in, the variable will fall back to this default value. If there is no default value, Terraform will interactively prompt the user for one.

- `type`
     This allows you to enforce type constraints on the variables a user passes in.
     Terraform supports a number of type constraints, including `string, number, bool, list, map, set, object, tuple`, and `any`. 
     It’s always a good idea to define a `type` constraint to catch simple errors. If you don't specify a `type`, Terraform assumes the `type` is `any`.

- `validation`
     This allows you to define custom validation rules for the input variable that go beyond basic type checks, such as enforcing minimum or maximum values on a number.

- `sensitive`
     If you set this parameter to true on an input variable, Terraform will not log it when you run plan or apply.
     You should use this on any secrets you pass into your Terraform code via variables: e.g., passwords, API keys, etc.

Here is an example of an input variable that checks to verify that the value you pass in is a number:
```
variable "number_example" {
  description = "An example of a number variable in Terraform"
  type = number
  default = 42
}
```
And here’s an example of a variable that checks whether the value is a list:
```
variable "list_example" {
  description = "An example of a list in Terraform"
  type = list
  default = ["a", "b", "c"]
}
```
You can combine type constraints, too. For example, here’s a list input variable that requires all of the items in the list to be numbers:
```
variable "list_numeric_example" {
  description = "An example of a numeric list in Terraform"
  type = list(number)
  default = [1, 2, 3]
}
```
And here’s a map that requires all of the values to be strings:
```
variable "map_example" {
  description = "An example of a map in Terraform"
  type = map(string)
  default = {
    key1 = "value1"
    key2 = "value2"
    key3 = "value3"
  }
}
```
You can also create more complicated structural types using the `object` `type` constraint:
```
variable "object_example" {
  description = "An example of a structural type in Terraform"
  type = object({
    name = string
    age  = number
    tags = list(string)
    enabled = bool
  })

  default = {
    name    = "value1"
    age     = 42
    tags    = ["a', "b", "c"]
    enabled = true
  }
}
```
The preceding example creates an input variable that will require the value to be an object with the keys name (which must be a string),
age (which must be a number), tags (which must be a list of strings), and enabled (which must be a Boolean).
If you try to set this variable to a value that doesn’t match this type, Terraform immediately gives you a type error.
The following example demonstrates trying to set enabled to a string instead of a `Boolean`:

```
variable "object_example_with_error" {
  description = "An example of a structural type in Terraform with an error"
  type = object({
    name = string
    age  = number
    tags = list(string)
    enabled = bool
  })

  default = {
    name    = "value1"
    age     = 42
    tags    = ["a', "b", "c"]
    enabled = "invalid"
  }
}
```
You get the following error:
```
$ terraform apply
Error: Invalid default value for variable on variables.tf line 78, in variable 
"object_example_with_error":
78: default = {
79:   name = "value1"
80:   age  = 42
81:   tags = ["a", "b", "c"]
82:   enabled = "invalid"
83: }
```
This default value is not compatible with the variable's type constraint: a bool is required.

Here's an example of variable value validation. It ensures that only `t2.micro` and `t3.micro` values can be passed to variable `ec2_instance_type`.
If there's anything else passed it triggers an error with a text message.
The `validation` block cosists of `condition` parameter that you can read like if value passed to `var.ec2_instance_type` variable 
contains one of the values of the list `["t2.micro", "t3.micro"]` then everything looks good. 
```
variable "ec2_instance_type" {
  type        = string
  default = "t2.micro"
  description = "The type of the managed EC2 instances."

  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.ec2_instance_type)
    error_message = "Only t2.micro and t3.micro instances are supported."
  }
}
```

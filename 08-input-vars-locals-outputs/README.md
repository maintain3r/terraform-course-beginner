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
     A variable can have multiple variations.
     Example:
     ```
     variable "ec2_instance_config_list" {
       type = list(object({
         instance_type = string
         ami           = string
       }))

       default = []

       validation {
         condition = alltrue([for config in var.ec2_instance_config_list : contains(["t2.micro"], config.instance_type) ])
         error_message = "Only t2.micro instances are allowed."
       }

       validation {
         condition = alltrue([ for config in var.ec2_instance_config_list : contains(["nginx", "ubuntu"], config.ami) ])
         error_message = "At least one of the provided \"ami\" values is not supported.\nSupported \"ami\" values: \"ubuntu\", \"nginx\"."
       }
     }
     ```
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

### Working with *.auto.tfvars
TF does not apply values from files with values for each variable automatically as in the previous example with dev.terraform.tfvars and prod.terraform.tfvars file.
TF automatically finds nd reads variable values from files named as terraform.tfvars or *.auto.tfvars.
Note that `*.auto.tfvars` will override `terraform.tfvars`.

In this example the prod.auto.tfvars files are automatically loaded by Terraform when it runs.
The values in the *.auto.tfvars files override the values in the terraform.tfvars file.
This means that if you have the same variable defined in both the terraform.tfvars file and an *.auto.tfvars file, the value from the *.auto.tfvars file will be used.

If you have more than 1 `*.auto.tfvars` fil ein your project directory, TF will sort the `*.auto.tfvars` filenames in alphabetical order,
and the filename that goes first gets overriden by the file that goes after it.
As an example, if we create 2 auto files - dev.auto.tfvars and prod.auto.tfvars files, dev filename goes first, then TF finds another auto file and it overrides the variables
that were in dev and now in prod auto file. This is an example of how you should avoid doing.

There might be another example where you have all your variables in `terraform.tfvars` file, but some of the variables are overriden in *.auto.tfvars file.

E.g.
```
$ cat terraform.tfvars
instance_type = "t2.micro"
image_id      = "11111111"
tags = {
        banagedBy = "TF"
}

$ cat prod.auto.tfvars
image_id      = "77777777"
```
If ou run terraform plan cmd you'll see that TF grabs `instance_type` and `tags` from terraform.tfvars file but `image_id` is "7777777".
Here's how its logic works:
- TF goes with the order of precedence from high -> low. `*.auto.tfvars` is higher than `terraform.tfvars`, it reads what it finds in it - in this case `image_id = "77777777"`.
  There's no other variable in this file.
- TF moves forward with checking for other variables in any other source and finds `terraform.tfvars` file, it reads every variable that TF didn't see in the revius file `*.auto.tfvars`,
  and again, following the variable precedence order. TF reads variable `instance_type`, `tags`, but it ignores the variable `image_id` as it has seen it coming from a more preferred source - `*.auto.tfvars.`

If for some reason you have same variable you repeat passing it as a cmd line argument, `terraform plan -var "myvar=10" -var "myvar=20"`,
then TF will stick to values that it reads the last, in this case it will stick to `myvar=20`.
Passing vars from different sources to cmd line will look the same as repaeting the same var mltiple times.
E.g. `terraform plan -var "myvar=10" -var-file myvars.tf`, then if myvar is in the myvars.tf file then it will be the last value TF will go with.

Don't use mutiple tfvars files that can potentially override each other!

### Locals
Locals provide a way to define a variable that can be reused within your module without needing to pass it in as an input variable.
Locals can't be set explicitly from th outside as a variable.
Locals can be any other supported type and can be referenced by other parts of your TF config.
Locals can be put in its own file, e.g. `locals.tf` and there's no such a thing like importing locals from another *.tf config file as long as all files are in the same directory.
You just reference the local variables in your output, resoruces, data sources. Locals can have hardcoded values or reference variables for the values.
Locals are used like internal variables in a function like in c/c++ when you implement a sorting algorithm you use some local to your function variables to store some
values while your function performs an action. Locals in TF can be used to more for different cases especially when they are used with terraform built-in functions.
If you try to pass a value to a variable defined in the `locals` block and if there's no regular variable in your project with the same name, you'll get an error:

$ terraform plan -var 'common_tags="{bu="QAZ"}"'
Error: Value for undeclared variable
│
│ A variable named "common_tags" was assigned on the command line, but the root module does not declare a variable of that name. To use this value, add a "variable" block to the configuration.

In this case, `common_tags` is a local variable and there's no regular variable with the same name, which is why TF throws an error.

### Outputs
Outputs are a way to expose data about your resources and modules, and can be very helpful in understanding the state of your resources or for integrating with other systems.
It's a good practive to move `outputs` into a separate file.
```
output "name" {
  description = ""
  value       = ""
}
```

To retrieve the output value outside terraform, run the command `terraform output output_name`.
The outputs can be pulled into cli and what's more interesting, outputs from modules can be retrieved by root TF project, and they can also be used as inputs to other modules.
You can read the output value of another project and use it as an input variable to your project.
For example you have a project that manages your VPC and this project has some Outputs that contain some useful information that you'd like to use in another project, say RDS.
Now, in RDS project directory when your run `terraform apply` you can pass it some input parameters and those parameters you can fetch from the other project's output section by
specifying the state file of VPC project using `-state` cli param.

Example of using outpus:
$ terraform output s3_bucket_name              - print output called `s3_bucket_name` in quotes
$ terraform output -raw s3_bucket_name         - pring output called `s3_bucket_name` without quotes
$ curl $(terraform output -raw s3_bucket_name) - connects to the bucket retrieved from TF outputs

Retrieve output named `list_of_objects_element_0_name` from another project and make it as an rgument to 'echo' linux cmd.
~/terraform-course-beginner/my-exercises/05-outputs (main)$ echo "My name is $(terraform output -raw -state ../03-variables.tf/terraform.tfstate list_of_objects_element_0_name)"
My name is Rossey

If your backend is S3 you can retrieve some output values from a project and use it for CI/CD for example.
The description you set to your output can't be retrieved from the command line.

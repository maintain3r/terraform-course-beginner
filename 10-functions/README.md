### Functions
TF has a rich set of built in functions that can be used for different purposes.
The functions are split into different categories and allow you to perform different actions, transformations, checks and other operations with data.
You can use functions as arguments to other functions, e.g.  func1(func2(...))
You can get more information including examples of usage of each function in the official documantaion https://developer.hashicorp.com/terraform/language/functions

```
$ cat functions.tf 

locals {
  name = "Perpey"
  age  = 10
  my_object = {
    key1 = 10
    key2 = "my_value"
  }
}

output "upper_case" {
  value = upper(local.name)
}

output "starts_with" {
  value = startswith(lower(local.name), "perp")
}

output "num_power_of" {
  value = pow(local.age, 4)
}

# read users.yaml config, decode it access all name values of a list type variable `users`
output "yaml_config" {
  value = yamldecode(file("${path.module}/users.yaml")).users[*].name
}

output "locals_to_json" {
  value = jsonencode(local.my_object)
}

$ cat users.yaml 
users:
- name: Lauro
  group: developers
- name: John
  group: auditors
```

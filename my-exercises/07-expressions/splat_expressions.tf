# Splat function in TF works with only lists and allow accessing subitems no matter what the keys is
# Splat function has '*' sign in square brakets and is a placeholder for the index of the list type data we process.
# In this example objects_list is a list of maps with 2 fields - firstname and lastname.
# Splat expresion simply allows you to access the values of the list without passing the index number of the item in the list
locals {
  firstnames_using_splat = var.objects_list[*].firstname
}

output "firstnames_using_splat" {
  value = local.firstnames_using_splat
}

output "numbers_list_splat" {
  value = var.numbers_list[*]
}

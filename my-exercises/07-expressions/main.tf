# TF supported expression types
# comparison: <,<=,>,>=,==, !=
# math: +,-,*,/
# bool: true, false, &&, ||
locals {
  math        = 2 * 5
  comparison  = 5 < 4
  boolean_or  = false || true
  boolean_and = false && false
}

# For expressions with lists
locals {
  double_numbers = [for num in var.numbers_list : num * 2]
  even_numbers   = [for num in var.numbers_list : num if num % 2 == 0]
  firstnames     = [for item in var.objects_list : item.firstname]
  fullnames      = [for item in var.objects_list : "${item.firstname} ${item.lastname}"]
}

output "expressions_suported" {
  value = {
    math        = local.math
    comparison  = local.comparison
    boolean_or  = local.boolean_or
    boolean_and = local.boolean_and
  }
}

output "for_expression_with_lists" {
  value = {
    double_numbers = local.double_numbers
    even_numbers   = local.even_numbers
    firstnames     = local.firstnames
    fullnames      = local.fullnames
  }
}


# For expressions with maps
locals {
  doubles_map = { for key, value in var.numbers_map : key => value * 2 }
  even_map    = { for key, value in var.numbers_map : key => value * 2 if value % 2 == 0 }
}

output "for_expression_with_maps" {
  value = {
    doubles_map = local.doubles_map
    even_map    = local.even_map
  }
}

# transform the var.users list into a map where the username property becomes the key in the map, and the role property becomes the value. 
# Variable 'var.users' is a list of maps and each map can have the same Key as in othe relemnts of the list.
# Having a duplicated key will throw an error. Use the ellipsis operator '...' at the end of 'item.role' to group together all the roles for a single username under the same map key.
locals {
  users_map = { for item in var.users : item.username => item.role... }
}

output "users_map" {
  value = local.users_map
}

# transform local.users_map into a new map with the following structure: <key> => { roles = <roles list> }
locals {
  users_map2 = { for key, value in local.users_map : key => { "roles" = value } }
}

output "users_map2" {
  value = local.users_map2
}

# return a list of roles for a specific username
# you can access the value of a key in the map by using same principle as in python mymap["mykey"] or mymap[key] if keu is a var
# in this case we get a value of var.user_to_output from user input, then we use it with local.users_map2 in brakets [] as key 
# and get access to local.users_map2[var.user_to_output] which returns as a value as a subfield 'role' which is a list.
# finally it looks like mymap[key].roles ad returns a list of roles for a specific key gioven by user as input to TF
output "user_to_output_roles" {
  value = local.users_map2[var.user_to_output].roles
  # less optimal but same result value = [ for username, roles in local.users_map2 : roles.roles if username == var.user_to_output ]
}

# transform 'local.users_map' map into a list containing only the username of each map entry
locals {
  usernames_from_map = [for username, roles in local.users_map : username]
  # We can also use usernames_from_map = keys(local.users_map) instead of manually creating the list!
}

output "usernames_from_map" {
  value = local.usernames_from_map
}

# Using values() function get all values of a specific key in map local.users_map
output "all_values_from_map" {
  value = values(local.users_map)
}

## for expressions with lists
Like in many programming languages TF supports 'for' expression that allows running in a loop through a list of items.
In TF for works with `list, set, tuple, map, object`.
Using `for` you can iterate over a list and produce a list, you can iterate over a list and produce a map, you can iterate over a map and produce a list, you can iterate over a map and produce a map.
During each iteration, for extracts an item and returns it back in a list. 
But the main point here is that you can perform some actions on every extracted item of the list.
Let's see an example of working with list variable using `for` loop.

```
$ cat variables.tf
variable "numbers_list" {
  type = list(number)
}

variable "objects_list" {
  type = list(object({
    firstname = string
    lastname  = string
  }))
}

$ cat terraform.tfvars
numbers_list = [1, 5, 7, 4, 3, 5]

objects_list = [
  {
    firstname = "Perpey"
    lastname  = "Katakata"
  },
  {
    firstname = "Pur-pur"
    lastname  = "Mur-mur"
  }
]

$ cat main.tf
locals {
  double_numbers = [for num in var.numbers_list : num * 2]
  even_numbers   = [for num in var.numbers_list : num if num % 2 == 0]
  firstnames     = [for item in var.objects_list : item.firstname]
  fullnames      = [for item in var.objects_list : "${item.firstname} ${item.lastname}"]
}
```

### double_numbers = [for num in var.numbers_list : num * 2]
Using `for` you can iterate over a list and produce a list, you can iterate over a list and produce a map, you can iterate over a map and produce a list.
The square brakets on the left and right in this expression `[for num in var.numbers_list : num * 2]` tell us that we're creating another list as an end result.
For each iteration in `var.numbers_list variable` of type `list` `for` extracts an item, in our case we store it in `num` temporary variable, but before returning it back we multiply it by 2.
Once multiplied by 2, the result is added into a another temporary list and the operation repeats with each element of `var.numbers_list` variable until `for` reaches its last element.
If you don't perform any operations with the item extracted on each iteration you'll receive the same items in a list as a result. 
The item of a list is returned every iteration and we can access it after the colon sign ':' within our `for` expression.
In the example below we simply get access to an item we extracted from `var.numbers_list` and witout doing anything we add it into a tmp list and as soon as for reaches the end, 
we get another list of valies returned, which in this case is basically the same list variable `var.numbers_list`.
This will return the same list of items from var.numbers_list:  `[for num in var.numbers_list : num ]`
This construct really looks like a `generator` in python. 
For example to get all items in a list multiplied by 2 as in `double_numbers = [for num in var.numbers_list : num * 2]`, in python it will look like this:
`double_numbers = [ num*2 for num in var.numbers_list ]`

### even_numbers   = [for num in var.numbers_list : num if num % 2 == 0]
Read it this way.
`for` loop extracts items one by one and stores them temporarily in `num` variable.
After colon sign ':' we return the value stored in `num`, but before returning it, we check if it matches our condition `num % 2 == 0`.
If there's a match, we add `num` into a temporary list and move forward with the next item in the loop, otherwise we don't add num into the tmp list and move forward with another item for gives us.
Python analogy would look like this: `[num for num in numbers_list if num %2 ==0]`


## for expression with maps
In TF for loop can be used with maps as well. You can create a list from maps, maps from lists, lists from lists, maps from maps. 
You can read data structures in one format and convert them in another. This is very powerful.
In the following example as you can see we're creating a map as a final result based on the curly braces one each side of the expression.
To create a final map, we iterate through `var.numbers_map` variable and since we're dealing with a map variable, for each iteration we extract a key=>value pair. 
`key => value` in expression is the TF way you access a key-value pair. 
If you don;t modify value nor key and leave `key => value` alone you'll simply get a copy of your initial map variable - `doubles_map = { for key, value in var.numbers_map : key => value  }`
And similarly to the example with lists you get access to the temporary variables in this case key and value and can run some checks against them before you return the `key => value` pair to a new resulting map.
```
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
```
This expression `doubles_map = { for key, value in var.numbers_map : key => value * 2 }` extracts `key` and `value` as pairs every iteration and returns a new key=>value pair where the value is multiplied by 2.
This expression `even_map    = { for key, value in var.numbers_map : key => value * 2 if value % 2 == 0 }` checks if the value of a key = > value pair is even, and if it is, 
it multiplies the value by 2 and returns the newly created key => value pair into a remporary map. Once loop finishes checking all map elements it returns a resulting map.

Depending on your values in the `numbers_map` variable if you run TF you'll see something like the this:
```
for_expression_with_maps = {
  "doubles_map" = {
    "five" = 10
    "four" = 8
    "one" = 2
    "seven" = 14
    "six" = 12
    "three" = 6
    "two" = 4
  }
  "even_map" = {
    "four" = 8
    "six" = 12
    "two" = 4
  }
}
```
### Accessing keys and values in a map
Access to a values andd keys can be done using keys() and values() functions.
You can also access the value of a specific key in python style.
E.g. myusers_db[username].roles will return a list of roles for a specific user; username in this case is a variable
















Transform the var.users list into a map where the username property becomes the key in the map, and the role property becomes the value. 
Variable 'var.users' is a list of maps and each map can have the same Key as in othe relemnts of the list.
Having a duplicated key will throw an error. Use the ellipsis operator '...' at the end of 'item.role' to group together all the roles for a single username under the same map key.
```
var.users content:
users = [
  {
    username = "Ivan"
    role     = "Sysadmin"
  },
  {
    username = "Vlad"
    role     = "Surgerist"
  },
  {
    username = "Perpey"
    role     = "Kata-kata"
  },
  {
    username = "Purka"
    role     = "Murka"
  },
  {
    username = "Ivan"
    role     = "Netadmin"
  },
  {
    username = "Ivan"
    role     = "DevOps"
  },
]

Using `for` loop, every iteration we get an item from the `users` variable of typoe list.
Then we create a map (as you can see we have curly brakets at each end of the expression) 
with key and value which we extract from each item using dot notation access.
To deal with potential key duplicates, TF supports `...` ellipsis opeartor that allows grouping all possible values into one group of values for the duplicate keys.
```
locals {
  users_map = { for item in var.users : item.username => item.role... }
}

Result:
users_map = {
  "Ivan" = [
    "Sysadmin",
    "Netadmin",
    "DevOps",
  ]
  "Perpey" = [
    "Kata-kata",
  ]
  "Purka" = [
    "Murka",
  ]
  "Vlad" = [
    "Surgerist",
  ]
}
```

Transform local.users_map into a new map with the following structure: <key> => { roles = <roles list> }
```
locals {
  users_map2 = { for key, value in local.users_map : key => { "roles" = value } }
}

Result:
users_map2 = {
  "Ivan" = {
    "roles" = [
      "Sysadmin",
      "Netadmin",
      "DevOps",
    ]
  }
  "Perpey" = {
    "roles" = [
      "Kata-kata",
    ]
  }
  "Purka" = {
    "roles" = [
      "Murka",
    ]
  }
  "Vlad" = {
    "roles" = [
      "Surgerist",
    ]
  }
}
```

### Return a list of roles for a specific username.
You can access the value of a key in the map by using same principle as in python mymap["mykey"] or mymap[key] if key is a variable.
In the following example `var.user_to_output` is a variable from command prompt, and it's used as a Key to extract value from `users_map2` map using square brakets []. 
The using `dot` it accesses role `field` of the returned value and returns us a list of roles for a specific user.
```
output "user_to_output_roles" {
  value = local.users_map2[var.user_to_output].roles
}
less optimal but same result value = [ for username, roles in local.users_map2 : roles.roles if username == var.user_to_output ]

Result if user enter Ivan as an input to terrform apply:
user_to_output_roles = [
  "Sysadmin",
  "Netadmin",
  "DevOps",
]

```

### Transform `users_map` map into a list containing only the username of each map entry
```
locals {
  usernames_from_map = [for username, roles in local.users_map : username]
}
You can also use usernames_from_map = keys(local.users_map) instead of manually creating the list!
```
```
Using values() function get all values of a specific key in map local.users_map
output "all_values_from_map" {
  value = values(local.users_map)
}
```
Note, you can write your expression right in the output section and attach it to value param of the output.

### Splat expression
TF support splat expression `[*]` which only allows you to access the values of a list without specifying the index number of the element in the list.
Splat function in TF works with only lists and allow accessing subitems no matter what the keys is
Splat function has '*' sign in square brakets and is a placeholder for the index of the list type data we process.
In this example objects_list is a list of maps with 2 fields - firstname and lastname.
Splat expresion simply allows you to access the values of the list without passing the index number of the item in the list 

```
objects_list = [
  {
    firstname = "Perpey"
    lastname  = "Katakata"
  },
  {
    firstname = "Pur-pur"
    lastname  = "Mur-mur"
  }
]

locals {
  firstnames_using_splat = var.objects_list[*].firstname
}

output "firstnames_using_splat" {
  value = local.firstnames_using_splat
}
```
Will output
```
tolist([
  "Perpey",
  "Pur-pur",
])
```

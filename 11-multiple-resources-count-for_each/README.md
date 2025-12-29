## Creating Multiple Resources
As we discussed in meta arguments section there are two meta arguments `count` and `for_each` allowing us to create multiple copies of a resource.
While they both create multiple resources they work differently and have their use cases.

## count
- Used to define the number of instances of a specific resource Terraform should create.
- It can be used with `modules` and with `resources`.
- Must be known before Terraform performs any remote resource actions.
- <TYPE>.<LABEL>.[<INDEX] refers to a specific instance of a resource, while <TYPE>.<LABEL> refers to the resource as a whole.
- We can use `count.index` in the resource's arguments to retrieve the index of the specific instance.
  Therefore `count` it's good to work with variables of type `list` when we need to get a specific item of list variable by accessing it by `count.index`.
- The index starts from 0. For example you set count to 2, you'll create 2 instances of resources and the index will strat from 0 and stop at 1. 
  This in total gives you 2 resources. Don't confuse count=2 with index elements going like 0,1,2.

Example:
```
resource "aws_instance" "multiple" {
  count         = var.ec2_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Project = local.project
    Name    = "${local.project}-${count.index}"
  }
}
```
As you can see, `count.index` is referenced in Name tag to create a value for it.
When you create a number of resources using `count` you create a list of resource of the same type.
You can later refer to a specific resource of the series of resources of the same type you created.
Here's a few examples of resource type "random_id". This resource type does not require any clouds and costs nothing.
```
locals {
  mixers_total = 5
  mixer_prefix = upper("randomizer")
}

Create 5 copies of `random_id` using count meta arg.
For each resource set `byte_length` referencing `count.index` to get the current index.
Set prefix for each resource reverencing `count.index` and adding it to a 

resource "random_id" "randomizer" {
  count       = local.mixers_total
  byte_length = count.index +1
  prefix      = "${local.mixer_prefix}-${count.index}-"
}

In this block we pretend we create ec2 instances and we want to distribute them in different subnets 
We want to make sure the instances are created and put in different subnets not matter how many subnets we have
Using modulus operation ${count.index} % ${local.vpc_subnets} we get values 0 or 1 which can be used to use it 
as index value for referencing a subnet from the list of subnets.
Note we need 2 subnets to exist in real world

resource "random_id" "ec2_instance" {
  count = local.mixers_total
  byte_length = count.index +1
  prefix      = "using_subnet-${count.index % local.vpc_subnets} for instance ${count.index}"
}


The block above creates 5 resources which are packed in to `random_id.randomizer` variable which is a list.
To access each resource individually use `random_id.randomizer` with an index like `random_id.randomizer[count.index]`
In this `for` expression we go through `random_id.randomizer` list and for each resource we extract, we get `hex` field from it.

output "all_count_randomizers_one_by_one" {
  value = [for i in random_id.randomizer : i.hex]
  # value = random_id.randomizer[*].hex
}

This output prints all 5 random_id.randomizer resources at once; you;ll see a list of random_id.randomizer resources
output "all_randomizers_as_list" {
  value = random_id.randomizer
}

This output prints the size of the list containing all randomizer resources using TF `length()` function and concatenates it with some text in upper case using `upper()` function.
output "number_of_randomizer_resources_in_list" {
  value = "There's ${length(random_id.randomizer)} ${(upper("randomizer"))} resources in total."
}

This is how you get the first randomizer object frm the list
output "get_first_randomizer" {
  value = random_id.randomizer[0]
}

Here's how terraform keeps in its state file resources created by `count` operator:
# random_id.randomizer[0]:
resource "random_id" "randomizer" {
    b64_std     = "RANDOMIZER-0-qg=="
    b64_url     = "RANDOMIZER-0-qg"
    byte_length = 1
    dec         = "RANDOMIZER-0-170"
    hex         = "RANDOMIZER-0-aa"
    id          = "qg"
    prefix      = "RANDOMIZER-0-"
}

# random_id.randomizer[1]:
resource "random_id" "randomizer" {
    b64_std     = "RANDOMIZER-1-DNY="
    b64_url     = "RANDOMIZER-1-DNY"
    byte_length = 2
    dec         = "RANDOMIZER-1-3286"
    hex         = "RANDOMIZER-1-0cd6"
    id          = "DNY"
    prefix      = "RANDOMIZER-1-"
}
As you can see, every resource is identified with an index number.

```
Bottom line.
When you create multiple resources using `count` meta argument the resources are packet into a list of same type objects.
If you create EC2 instances, smth like 
```
resource "aws_instance" "web_srv" {
  count = 3
  * * *
}
```
You'll have a list `aws_instance.web_srv` created which will contain all your web_srv resources in it and which can be accessed individually by index.
## NOTE: Using variabl fo type `list` can lead to undesired and bad outcomes. If you store your ec2 instance config in a list, which is a list of objects, 
## flipping the order of the items in the same list will make terraform destroy all instances and recreate them. This is because List in its nature is an ordered resource type, 
## where each element has its uniq index Id and TF treats this as a change even if it's not a change in regards to you infra.
## It's better to use maps to store your resource settings! Map its not an order based type, therefore it does nto cause any issues.



## for_each
- `for_each` accepts a map or a set of strings and creates an instance for each entry in the received expression.
- You can access the key and value via the each object using `each.value` or `each.key`.
  Key and value are the same if the received value is a set.
- You should not use sensitive values as arguments to the `for_each` meta-argument
- The `for_each` value must be known before Terraform performs any remote operations.
- You can chain for_each resources into other for_each expressions if we need to create multiple resources based on a map or set.
- When you create a resource and you use for_each to extract resources settings you can also use `locals` in case you need to determine some values dynamically.
  Since locals can refer to a data source as a variable value you can then reference it in you resource creations.

Example:
```
resource "aws_subnet" "main" {
  for_each   = var.subnet_config
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value.cidr_block

  tags = {
    Project = local.project
    Name    = "${local.project}-${each.key}"
  }
}
```

Unlike `count` that creates multiple resources and packs/represents them as a list of resource adressed by an index, 
`for_each` directive also creates multiple resources but tey're all represented as map of objects that uniqely identifies each resource
by a specific key. You can access each resource created by `for_each` by specifying a concrete key in that oject.
Note, like `count`, `for_each` still creates multiple resources of same type, it's just that they're represented differently as list and map.
To get a better idea check the following example.

### The following is an example of how to reference object fields and how to access a specific element in a map and object by a Key:
```
$ cat variables.tf
variable "mixer_config_tiers" {
  description = "Contains mixer configs for each type of mixer tier."
  type = object({
    golden = object({
      prefix      = string
      byte_length = number
    }),
    silver = object({
      prefix      = string
      byte_length = number
    }),
    bronze = object({
      prefix      = string
      byte_length = number
    })

  })
}

$ cat terraform.tfvars 
mixer_config_tiers = {
  golden = {
    prefix      = "golden"
    byte_length = 8
  },
  silver = {
    prefix      = "silver"
    byte_length = 5
  },
  bronze = {
    prefix      = "bronze"
    byte_length = 2
  }
}

$ cat main.tf
resource "random_id" "all_mixer_resource" {
  // each.key - represents the key name of the map
  // each.value - represents the value the the key is equal to 
  for_each    = var.mixer_config_tiers
  byte_length = each.value.byte_length
  prefix      = each.value.prefix
}

resource "random_id" "golden_tier_mixer" {
  byte_length = var.mixer_config_tiers["golden"].byte_length
  prefix      = var.mixer_config_tiers["golden"].prefix
}

Run `terraform apply -auto-approve` and create our resources.
Run `terraform show` to show allo resources in the state file

$ terraform show
// random_id.all_mixer_resource["bronze"]:      This item corresponds to random_id.all_mixer_resource = { "bronze"= { "b64_std"} = "bronzea8s=", "b64_url" = "bronzea8s", "byte_length" = 2, "dec" = "bronze27595", "hex" = "bronze6bcb", "id" = "a8s", "prefix" = "bronze" }
resource "random_id" "all_mixer_resource" {     this means that if we iterate over `random_id.all_mixer_resource` we'll get bronze, golden, silver as our keys, and for the vaues we'll get the rest of the object.
    b64_std     = "bronzea8s="                  Basically, bronze as a key has a value of an entire resource.
    b64_url     = "bronzea8s"                   Simply speaking, you pass a map variable to `for_each` which extracts keys one by one and cretaes a resource which is identified by that keyname
    byte_length = 2
    dec         = "bronze27595"
    hex         = "bronze6bcb"
    id          = "a8s"
    prefix      = "bronze"
}

// random_id.all_mixer_resource["golden"]:
resource "random_id" "all_mixer_resource" {     
    b64_std     = "goldenh0FjzhFSAww="
    b64_url     = "goldenh0FjzhFSAww"
    byte_length = 8
    dec         = "golden9746180805311464204"
    hex         = "golden874163ce1152030c"
    id          = "h0FjzhFSAww"
    prefix      = "golden"
}

// random_id.all_mixer_resource["silver"]:
resource "random_id" "all_mixer_resource" {
    b64_std     = "silverSc5ZveE="
    b64_url     = "silverSc5ZveE"
    byte_length = 5
    dec         = "silver316994600417"
    hex         = "silver49ce59bde1"
    id          = "Sc5ZveE"
    prefix      = "silver"
}

// random_id.golden_tier_mixer:
resource "random_id" "golden_tier_mixer" {
    b64_std     = "goldenYxWElio3btY="
    b64_url     = "goldenYxWElio3btY"
    byte_length = 8
    dec         = "golden7139758564754026198"
    hex         = "golden631584962a376ed6"
    id          = "YxWElio3btY"
    prefix      = "golden"
}

As you can see we have 3 resources created by `for_each` and every resources is uniqely identified by its key. 
You can reference a specific resource created by for_each using its key like this:
// print all resources in the state file
$ terraform state list
random_id.all_mixer_resource["bronze"]
random_id.all_mixer_resource["golden"]
random_id.all_mixer_resource["silver"]
random_id.golden_tier_mixer
```
// reference a concrete resource by its uniq key, escape quotes as bash removes them
$ terraform state show random_id.all_mixer_resource[\"bronze\"]
# random_id.all_mixer_resource["bronze"]:
resource "random_id" "all_mixer_resource" {
    b64_std     = "bronzea8s="
    b64_url     = "bronzea8s"
    byte_length = 2
    dec         = "bronze27595"
    hex         = "bronze6bcb"
    id          = "a8s"
    prefix      = "bronze"
}

```
If you create multiple resources using `count` and then switch to use for_each` or wise versa, terraform will destroy your resources created with `count` and recreate them with `for_each`.
This applies both way, count -> for_each, for_each->count.

Now add an output to your main.tf and apply the change.

output "list_mixer_resources" {
  value = { for key, value in random_id.all_mixer_resource  : key=>value.prefix }
}

$ terraform apply
random_id.all_mixer_resource["golden"]: Refreshing state... [id=h0FjzhFSAww]
random_id.golden_tier_mixer: Refreshing state... [id=YxWElio3btY]
random_id.all_mixer_resource["silver"]: Refreshing state... [id=Sc5ZveE]
random_id.all_mixer_resource["bronze"]: Refreshing state... [id=a8s]

You should see the following output.
Outputs:

list_mixer_resources = {
  "bronze" = "bronze"
  "golden" = "golden"
  "silver" = "silver"
}
````
In our output `list_mixer_resources` key corresponds to a concrete resource and its value corresponds to that resource properties.

### You can process a `list` type variable with `for_each` meta argument.
In this case `each.key` equals to `each.value`.
As a result resource created will be identified by `each.key` which is also `each.value`.
Example:
```
locals {
  lst = ["katakata","perpey","kutsi-kutsi"]
}

output "to_set" {
  value = toset(local.users_from_yaml[*].username)
}

resource "random_id" "process_list_variable_with_for_each" {
  for_each = toset(local.lst)  // local.lst is of type list, we have to explicitly convert it into set using toset() funtion
  byte_length = 2
  prefix = each.value
}

Terraform will perform the following actions:
  # random_id.process_list_variable_with_for_each["katakata"] will be created
  + resource "random_id" "process_list_variable_with_for_each" {
      + b64_std     = (known after apply)
      + b64_url     = (known after apply)
      + byte_length = 2
      + dec         = (known after apply)
      + hex         = (known after apply)
      + id          = (known after apply)
      + prefix      = "katakata"
    }

  # random_id.process_list_variable_with_for_each["kutsi-kutsi"] will be created
  + resource "random_id" "process_list_variable_with_for_each" {
      + b64_std     = (known after apply)
      + b64_url     = (known after apply)
      + byte_length = 2
      + dec         = (known after apply)
      + hex         = (known after apply)
      + id          = (known after apply)
      + prefix      = "kutsi-kutsi"
    }

  # random_id.process_list_variable_with_for_each["perpey"] will be created
  + resource "random_id" "process_list_variable_with_for_each" {
      + b64_std     = (known after apply)
      + b64_url     = (known after apply)
      + byte_length = 2
      + dec         = (known after apply)
      + hex         = (known after apply)
      + id          = (known after apply)
      + prefix      = "perpey"
    }
```
As you can see resources are identified by each.value. As for the prefix within the resource we could assign it any value we want.
This is just a demonstration of the possibility of using `for_each` meta argument in multiple resource creation.
Of course we could create the same amount of resource using `count` meta argument, but in that case we would identify our resources by a number, which is count.index.
Having a resource identified by a concrete key is beneficial as we can refer that particular resource by a name which we could store in a variable, 
like subnet_name when we want to create an EC2 instance and specify the subnet where it should be created.

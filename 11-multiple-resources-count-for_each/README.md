## Creating Multiple Resources
As we discussed in meta arguments section there are two meta arguments `count` and `for_each` allowing us to create multiple copies of a resource.
While they both create multiple resources they work differently and have their use cases.

### count
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


The block above creates 5 resources which are packed in to `random_id.randomizer` variable.
To access each resource individually use `random_id.randomizer` with an index liek `random_id.randomizer[count.index]`
In this `for` expression we go through `random_id.randomizer` list and for each resource we extract we get `hex` field from it.

output "all_count_randomizers_one_by_one" {
  value = [for i in random_id.randomizer : i.hex]
  # value = random_id.randomizer[*].hex
}

This output prints all 5 random_id.randomizer resources at once; you;ll see a list of random_id.randomizer resources
output "all_randomizers_as_list" {
  value = random_id.randomizer
}

This output prints the size of the list containing all randomizer resources using TF length() function and concatenates it with some text in upper case.
output "number_of_randomizer_resources_in_list" {
  value = "There's ${length(random_id.randomizer)} ${(upper("randomizer"))} resources in total."
}

This is how you get the first randomizer object frm the list
output "get_first_randomizer" {
  value = random_id.randomizer[0]
}
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


### for_each
- `for_each` accepts a map or a set of strings and creates an instance for each entry in the received expression.
- You can access the key and value via the each object using `each.value` or `each.key`.
  Key and value are the same if the received value is a set.
- You should not use sensitive values as arguments to the `for_each` meta-argument~
- The `for_each` value must be known before Terraform performs any remote operations.
- You can chain for_each resources into other for_each expressions if we need to create multiple resources based on a map or set.

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

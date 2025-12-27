# using upper() built in function bring mixer_prefix variable value to upper case
locals {
  mixers_total = 5
  mixer_prefix = upper("randomizer")
  vpc_subnets  = 2
}

resource "random_id" "randomizer" {
  count       = local.mixers_total
  byte_length = count.index +1
  prefix      = "${local.mixer_prefix}-${count.index}-"
}

# pretend we create ec instances and we want to distribute them 
# in different subnets regardless of how many subnets we have
# ${count.index} % ${local.vpc_subnets} will give results 0 or 1 therefore we'll always be in one of 
# the subnets. Note we need 2 subnets to exist in real world
resource "random_id" "ec2_instance" {
  count = local.mixers_total
  byte_length = count.index +1
  prefix      = "using_subnet-${count.index % local.vpc_subnets} for instance ${count.index}"
}

output "all_count_randomizers_one_by_one" {
#  value = [for i in random_id.randomizer : i.hex]
   value = random_id.randomizer[*].hex
}

output "all_randomizers_as_list" {
  value = random_id.randomizer
}

output "number_of_randomizer_resources_in_list" {
  value = "There's ${length(random_id.randomizer)} ${(upper("randomizer"))} resources in total."
}

output "get_first_randomizer" {
  value = random_id.randomizer[0]
}

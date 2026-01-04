## Object Validation
Allows creating more reliable infrastructure through `preconditions`, `postconditions`, and `check assertions`.

### Preconditions
```
lifecycle {
  precondition {
    condition     = ...
    error_message = "..."
  }
}
```
- Used from within resources and data blocks
- Cannot reference the resource itself.
- Can be used to check the validity of data blocks or variables that the resource references.


### Postconditions
```
lifecycle {
  postcondition {
    condition     = ...
    error_message = "..."
  }
}
```
- Used from within resources and data blocks
- Can reference the resource itself by using special keyword `self`.
  E.g. `self.instance_type` references instance_type field of the ec2 resource while located within the same resource.
- Can be used to check the validity of the resource's configuration.


### Check assertions
```
check "my_custom_check" {
  assertion {
    condition     = ...
    error_message = "..."
  }
}
```
- Used from outside resources and data blocks
- Can reference information from across the current Terraform project.
- Results only in a warning and does not stop the apply process.


### Core Differences
Precondition:
- Validates assumptions `before` a resource is created or modified.
- Evaluated after planning but before the actual resource operation.
- self Reference Not allowed (the resource doesn't exist or is being modified).
- Common use case: Checking if a provided AMI has the correct CPU architecture.

Postcondition:
- Validates guarantees `after` a resource is created or updated.
- Evaluated after the resource operation is complete.
- self Reference Allowed and common; used to check the actual attributes returned by the provider.
- Common use case: Ensuring an EC2 instance was assigned a specific private DNS or public IP.
- If postocondition block relies on information that's only available after object creation, then this check won't be performed at PLAN phase, it will be done after APPLY phase.
  Note that postcondition does not prevent from resource to be created, terraform creates the resources and after creating postfactum performs checks pecified within the postcondition block,
  and if check fails terraform stops executing the nxt steps of the project and throws an error. It's like a circuit brealer that stops executring any urther operations in the project.
  
- Postcondition is more strict in a situation where you reference the resource parameter while it's hardcoded in the resource definition.

Execution and Failure Logic
- `Fail Fast`: Preconditions stop Terraform from even attempting to create a resource if requirements aren't met, saving time and potential costs.
- `Halt and Protect`: If a postcondition fails, Terraform stops execution immediately.
                      It does not undo the already created resource, but it prevents any downstream resources that depend on it from being created or updated.
- `Planning Phase`:   If Terraform can determine the result during the plan phase (e.g., checking a hardcoded variable), it will report the failure then.
                      If the result depends on data only available after creation (like a generated ID), it validates during the apply phase.

Additional notes:
Single `Lifecycle` Block: All preconditions and postconditions must live inside the same lifecycle block; you cannot have multiple lifecycle blocks per resource.
No Dynamic Blocks: You cannot use dynamic blocks to generate lifecycle rules.
Tainting Risk: If a terraform apply fails due to a postcondition, the resource might be created but in an "unfinished" state according to your logic. Terraform will record the check result in the state file.
Avoid Redundancy: Do not use postconditions for values you can already check in a precondition or via standard variable validation. Postconditions are best reserved for "known after apply" attributes.
Check Blocks: For non-blocking validations that you want to run even if they fail, use the check block instead of lifecycle postconditions. 
Even if checks in PLAN phase succeed it's not a guarantee that the APPLY phase will go through and this is because apply phase information is only available after resource has been created.
This also means that postcondition checks are postponed until the resource gets created, then TF performs the checks if there are any specified within the resource
and if everything passes well it continues with the next operation in the project.

## Check assertion
This block lives outside of data and resource blocks and does not stop TF if statemends defined in checks fail. Check block has access to all resources within the project.
This is only used to warn a user of the project that there's something wrong or missing, like tags, or maybe resources are been deployed in the same AZ leading to bad reliability design.
Example:
```
ata "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "this" {
  count      = 4
  vpc_id     = data.aws_vpc.default.id
  cidr_block = "172.31.${128 + count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[
    count.index % length(data.aws_availability_zones.available.names)
  ]

  lifecycle {
    postcondition {
      condition     = contains(data.aws_availability_zones.available.names, self.availability_zone)
      error_message = "Invalid AZ"
    }
  }
}

check "high_availability_check" {
  assert {
    condition     = length(toset([for subnet in aws_subnet.this : subnet.availability_zone])) > 1
    error_message = <<-EOT
      You are deploying all subnets within the same AZ.
      Please consider distributing them across AZs for higher availability.
      EOT
  }
} 
```

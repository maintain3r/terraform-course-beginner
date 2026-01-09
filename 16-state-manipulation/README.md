## State Manipulation
## Recreate, import, refactor, and untrack infrastructure within Terraform

### - Tainting:
Force the recreation of a resource that is tracked by a Terraform configuration.
Can be used when a certain resource goes into an invalid state, but the configuration is correct and hasn't changed.
You force TF to recreate the resource even if it already exists and it's in the TF state file.
You force TF recreate the resource without changing the configuration it's used in cases where you want to forcefully recreate 
an infra resource that misbehaves even if TF has already created it in the past.
Without tainting TF will check its state and will see the resource has been created already it will NOT recreate it - standard behavior.

### - Importing:
Import existing resources into a Terraform project, and start managing them with Infrastructure as Code.
Can be achieved using:
- $ terraform import aws_s3_bucket.example bucket-name
- `import` config block in config files
```
   import {
    to = aws_s3_bucket.example
    id = "bucket-name"
  }
```
Each resource you create using a specific provider like aws has an `import` section in the official documentation.
It's important to read that section to get a better idea of the examples and specifics of importing a concrete resource. 

### - Refactoring:
Rename resources without recreating them, and move them inside and outside of modules whenever needed.
Prevents recreation due to changing resource addresses in Terraform.
If you change resource reference name, TF will not find it's name in ints state file nor it will find the old name of the resource.
As a result, TF will destroy an existing resoruce and create it under a different name. SO you end up recreating a resource just to rename it's reference name inside config file which makes no sense.
There are techniques that allow you renaming resource reference names within the code or using cmd line tools.
What TF does, it updates resource addresses in its state file. It can be useful when you already has some subnets in your infra and nwo you developed a networking module.
You want to rename existing subnets reference names so that TF updates its state file in a way so that the existing subnets have module name in their unique names as they were created by networking module.
Can be achieved:
- using cli `terraform state mv <old resource uniq name>  <new resourc uniq name>`
- using terraform `moved` block specified in *.tf config file

### - Untracking:
Remove a resource from a Terraform configuration without actually destroying that resource.
Useful when we want to manage the resource independently of the Terraform project.

### - Generating Configuration:
Leverage Terraform's code generation feature to generate a best-effort configuration based on existing resources. 
Can be used when importing resources into Terraform.
Usually goes together with importing, the config TF generates is not perfect but good starting point.

### - Fine-grained State File Changes:
Force state unlocking, and pull and push the state file from remote backends to perform careful, fine-grained editing in case something is wrong with it.



### Practical Examples - Refactoring; moved/mv
When we create resources in Terraform, we specify a resource type and give it a reference name.
```
resource "aws_instance" "web_srv" {
  ami = ...
  instance_type = ...
}
```
TF creates the resource and remembers it uniquely as `aws_instance.web_srv`.
If after creating we rename our resource and give it a new name as below. 
```
resource "aws_instance" "web_srv_apache" {
  ami           = ...
  instance_type = ...
}
```
Terraform will see that resource `aws_instance.web_srv` no longer exists in the project files and will plan to recreate it. 
the thing is TF does not track old resource names to understand that a resource was renamed.
From practical point of view recreating an existing resource makes no sense, especially if its PROD. No sense in edstroying `aws_instance.web_srv` and then creating new resource `aws_instance.web_srv_apache`.
To avoid recreating resources and causing potential downtime, you have to update the TF state file so that it references the same name as in the *.tf terraform configs.
There's 2 ways of renaming a resource without recreatign it.

### 1. Command prompt
$ teraform state mv <old-name> <new-name> - old-name is the `resource-type.name` that TF knos about from the `state` file; new-name is the `resource-type.new-name` of the resource in the *.TF config file after renaming
$ teraform state mv -dry-run <old-name> <new-name> - using dry-run you can test what's going to happen without applying the modification
$ terraform state mv "aws_instance.web_srv" "aws_instance.web_srv_apache" - which will rename resource address in TF state file to a new one so that it matches what's in *.tf config file

Note: If you run `terraform apply` TF should show 0 resources to add 0 to destroy.

- `Renaming resources created count meta argument`
Now we update the previous resource with `count` meta argument to create 2 instances. Remember, web_srv_apache resource exists.
```
   resource "aws_instance" "web_srv_apache" {
     count         = 2
     ami           = ...
     instance_type = ...
   }
```
In this case, the previous resource block modified so that it should create multiple instances of "aws_instance.web_srv_apache".
As it was discussed in previous lectures, `count` creates a list of objects.
In this case TF will check its state file and see that it actually has already a resource `"aws_instance.web_srv_apache"`, and it's smart enough to move it under "aws_instance.web_srv_apache[0]" 
and the only thing that remains is to create a new resource that will be identified as "aws_instance.web_srv_apache[1]". This will make 2 resources in total as needed.
If you run `terraform plan` TF will plan adding just 1 resource.
Run terraform apply and apply the change which will add 1 more reource.


- `Renaming resources created for_each meta argument`
You can use `for_each` meta argument to create multipe instances of a resource where each resource instance will be identified by its key.
Here's an updated version of a previous resource
```
   locals {
     instance_names = ["node1", "node2"]
   }

   resource "aws_instance" "web_srv_apache" {
     for_each      = toset(local.instance_nmes)
     ami           = ...
     instance_type = ...
   }
```
If you run terraform plan you should see TF planning for deleting 2 resources and adding 2.
To avoid deleting current instances and creating 2 new you update TF state so that the information in it corresponds to *.tf config files.
$ terraform state mv "aws_instance.web_srv_apache[0]"  'aws_instance.web_srv_apache["node1"]'
$ terraform state mv "aws_instance.web_srv_apache[1]"  'aws_instance.web_srv_apache["node2"]'

### 2. Moved
There's another way of doing the same thing using `moved` block in your *.tf config files.
It has a simple structure with only arguments `from` and `to` and it allows you to specify those renamings as part of your conig files instead of doing this from the cli. 
You can have multiple `moved` block in your config files and even create separate `moved.tf` config file just for moved stuff.
In this example, we rename each element of list aws_instance.web_srv_apache to another structure - map identifying each resource element by a key.
```
   locals {
     instance_names = ["node1", "node2"]
   }

   moved {
     from = aws_instance.web_srv_apache[0] 
     to   = aws_instance.web_srv_apache["node1"]
   }

   moved {
     from = aws_instance.web_srv_apache[1] 
     to   = aws_instance.web_srv_apache["node2"]
   }

   resource "aws_instance" "web_srv_apache" {
     for_each      = toset(local.instance_nmes)
     ami           = ...
     instance_type = ...
   }
```
After running `$ terraform plan` TF will show that it does not plan for creating or deleting resources, it will only show that it will rename resource names from one name to another.
To actually rename the resources run `$ terraform apply`.
Removing `moved` blocks from the config files does not make TF to destroy or create same resources. 
It's recommended to keep the `moved` blocks in the config files for historical reason.
You can also use `moved` block with resources created in modules.
You can use moved block individually for each resource or as a bulk move with single moved block.

In this example resource "random_id.randomizer" creates 3 resources which are identified by keys specified in `local.mixer_names`.
```
locals {
  mixer_names = ["golden","silver","bronze"]
}

# You must comment this resoruce block when you move resources under module othervise it will lead to a conflict; TF will see it as ambigous, 
# you wanna move these resouce under module and at the same time you wanna create them
# resource "random_id" "randomizer" {
#   for_each = toset(local.mixer_names)
#   byte_length = 5
#   prefix = "mixer"
# }
#   this are the resources this resource block created before move
#$ terraform state list
#random_id.randomizer["bronze"]
#random_id.randomizer["golden"]
#random_id.randomizer["silver"]

# Moving all resources from this root module to modules/mixer with one single move block at once instead of one-by-one
# NOTE: elements' keys in module MUST be the same as the ones initially created in this root module
moved {
  from = random_id.randomizer
  to   = module.mixer.random_id.moduled_mixer
}

module "mixer" {
  source = "./modules/mixer"
  mixer_names = local.mixer_names
}

$ terraform apply
module.mixer.random_id.moduled_mixer["golden"]: Refreshing state... [id=2D0glbY]
module.mixer.random_id.moduled_mixer["bronze"]: Refreshing state... [id=1LPf0Pc]
module.mixer.random_id.moduled_mixer["silver"]: Refreshing state... [id=lu7SUgM]

Terraform will perform the following actions:

  # random_id.randomizer["bronze"] has moved to module.mixer.random_id.moduled_mixer["bronze"]
    resource "random_id" "moduled_mixer" {
        id          = "1LPf0Pc"
        # (6 unchanged attributes hidden)
    }

  # random_id.randomizer["golden"] has moved to module.mixer.random_id.moduled_mixer["golden"]
    resource "random_id" "moduled_mixer" {
        id          = "2D0glbY"
        # (6 unchanged attributes hidden)
    }

  # random_id.randomizer["silver"] has moved to module.mixer.random_id.moduled_mixer["silver"]
    resource "random_id" "moduled_mixer" {
        id          = "lu7SUgM"
        # (6 unchanged attributes hidden)
    }

Plan: 0 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

$ terraform state list
module.mixer.random_id.moduled_mixer["bronze"]
module.mixer.random_id.moduled_mixer["golden"]
module.mixer.random_id.moduled_mixer["silver"]
```


### Importing existing resources.
Importing existing resources into TF can be done in different ways.
### NOTE: when you import a resource into TF, for safety reason you may want to add a `lifecycle` block and setting a policy `prevent_dstroy = true` 
### in case if a subsequent change in your config files plans on recreating or destroying this object.
### When you import existing resources you can even let TF generate a config for a resource you import using 

1. Import exising resource using cli command
First you have to create a resource block in your TF config file as you usually do when you create resources.
```
resource "aws_s3_bucket" "remote_state" {
  bucket = "the-name-of-the-existing-bucket"
}
```
Second, in the cli you run `terraform import aws_s3_bucket.remote_state 'the-name-of-the-existing-bucket'`
Basically, in the cli you reference a resource that you defined to be imported from AWS to TF.
If it succeeds TF will add the resuorce in its TF state and you'll start managing the resource from TF.
NOTE, it does not have to be populated with all params in its body, in fact, this resoruce body can be empty as TF uses it as a placeholder for import operation when you do it through cli.
In the resource block you can specify a bucket name that does not even exist. TF when imports a resource from your real infra into it `teraform.tfstate` file
needs a resource in your config as a placeholder for uniqly identifying the resource you import.
NOTE, in case bucket name in the config file is different from the s3 bucket name you imported, running terraform plan after importing will make TF plan for recreating the S3 resoruce.
This will make TF destroy the real existing S3 bucket in your infra and creating one that has a name specified in your TF config file.
NOTE, you can't import a real existing resource right from cli without defining a resource block for it in your *.t config file.
Example:
```
resource "aws_s3_bucket" "remote_state" {
  bucket = "s3_bucket_for_static_website"
}

$ terraform import <to> <id>;  to - this is how TF will see and maintain the imported real resource; id - this is an id of a real resource to be imported
$ terraform import "aws_s3_bucket.remote_state" 'static_website_s3_bucket' - TF looks for a real S3 bucket 'static_website_s3_bucket' in AWS and imports it in its state file identifying it as `aws_s3_bucket.remote_state`.
                                       If you run a subsequent terraform plan/apply cmd, it will see a drift between terraform.tfstate file and the config and will plan for destroying old S3 bucket and creating a new one.
                                       It's good to specify a `lyfecycle` block with `prevent_destroy = true`
```
Note that when you import an existing resource you don;t import what you specified in the resource block of your *.tf config file, 
you import the real existing resource with all its properties into TF state file and remember it under a resource name/id as specified in your config file.
If bucket name to import is different from what you have in your TF config file TF will still import the real resource and there will be no errores. 
Any subsequent plan/apply cmds will plan for destroying imported existing resoruce and creating a new one with the name specified in the config file.

2. Import using `import` config block
```
   import {
    to = aws_s3_bucket.example
    id = "bucket-name"
  }
```
Example below imports an S3 bucket `terraform_backend_prod` and `aws_s3_bucket_public_access_block` resource that blocks public access to `terraform_backend_prod` bucket.
This is done using `import` block in TF like `moved` block discussed above.

```
import {
  to = aws_s3_bucket.remote_state
  id = "terraform_backend_prod"
}

import {
  to = aws_s3_bucket_public_access_block.remote_state
  id = aws_s3_bucket.remote_state.bucket  // you could also specify bucket name as hardcoded value
}

resource "aws_s3_bucket" "remote_state" {
  bucket = "terraform_backend_prod"
}

resource "aws_s3_bucket_public_access_block" "remote_state" {
  bucket                  = aws_s3_bucket.remote_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```
Using `import` block does not need terraform import in cli.
Now if you run `terraform plan` cmd you'll TF planning only for importing resources into its state file.
To actually import the resource yo urun `terraform apply`. TF plan cmd does not do chages.
If you rerun terraform apply, TF should say nothing to change nor import.
You can kep `import` blocks in a separate config files even if they're no longer needed, TF already manages the imported resource. Yuo can delete the import resources once imported.
Keeping import blocks in a separate file is just a reminder that at some point you imported the resource specified in the `import` block.
Another interesting thing about importing resources is letting TF generate a config file for the imported resource.
In that case you don;t have to define placeholder resource in your config file for the importing resoruce.
You'll only need to define an import block and then run `terraform plan -generate-config-out=path-where-to-build-config-of-imported-resource`.
Example
```
import {
  to = aws_s3_bucket.remote_state
  id = "terraform_backend_prod"
}
```
`$ terraform plan -generate-config-out="remote_state_bucket.tf" - will generate a best effort config for s3 bucket
### Note, TF will create a config file with resource block but it may fail to populate it with all settings but it will still create the config file with the best effort resource definition.
### You'll then need to modify and polish the resource block to make it match the resource in the cloud.


### Removing resources from TF state file.
Remove is used when you need to stop tracking a resource in your TF project and letting another team manage it through their project.
This involves removing a resource not in your infra but only in TF state and config file so that it stops seeing it and thus stops managin it.
Simply speaing it makes TF forgetting the resource you need.
Commenting the resources in section above and running plan, TF will plan for deletign te resources as it will see a drift between the config files and the state file.
So, commentign resources to not manage them anymore is a dangerous this as it leads to destroying real resoruces that you might need to pass to another team.

1. Using `$ terraform state rm <resouce_type.resource_name>`
To see how you can remove a resource safely create an S3 bucket first to play with.
```
resource "aws_s3_bucket" "my_bucket" {
  bucket = "random_name_64565465465"
}

Run `terraform apply`
```
Now, to unlink/forget "aws_s3_bucket.my_bucket" resource there a 2 ways - cli and `removed` block in config files.
`$ terraform state rm -dry-run aws_s3_bucket.my_bucket` - will say `Would remove aws_s3_bucket.my_bucket' but since it` -dry-run it's not gonna do it
`$ terraform state rm aws_s3_bucket.my_bucket`          - will remove the bucket

Once TF removes the resource from its state file, you can remove the resource definion in config files ot comment it.
Running `terraform apply` now should say no resources to add nor delete.
At this point "random_name_64565465465" bucket still exists in AWS.
Let's import "random_name_64565465465" bucket back into TF state using terraform import cli cmd.
Before importing we have to create a resource definition in TF config file.
```
resource "aws_s3-bucket" "my_new-bucket" {
  bucket = "random_name_64565465465"
}
```
Now import our old existing bucket into TF state so that it remembers/tracks it as "aws_s3-bucket.my_new-bucket" resource.
`$ terraform import aws_s3-bucket.my_new-bucket "random_name_64565465465"`
If you remove "aws_s3-bucket.my_new-bucket" resource from your config file and run `terraform apply` - it will delete the resource.
But here its not what we need. Let's keep the resource for the next example.


2. Usin `removed` block in config file.
```
removed { 
  from = <resource type>.<resource name>
  lifecycle { 
    destroy = true | false
  }
}
```
`destroy = true`  - destroy the resource
`destroy = false` - only forget the object without destroying it from infra

Open the configuration file that contains the resource block we used to import the existing resource under a new name.
We'll comment the resource block and run `terraform plan`.
Note, if we don't comment the resource TF will see a conflict where we need a resource specified in `resouce` block and at the same time `remoed` block requiring TF to delete te resource.

```
removed {
  from = aws_s3-bucket.my_new-bucket
  lifecycle {
    destroy = false
  }
}

#resource "aws_s3-bucket" "my_new-bucket" { 
#  bucket = "random_name_64565465465"
#}
```

Depending on what you put in `lifecycle { destroy = false }` block TF will remove the resource entirely from its state and infra (true), 
or just will remove the resoruce from its sttae file while leaving the resource in infra to exist (false).
While you can always remove the entire resource from config files and then run terraform apply to remove the resource, 
which is similar to `lifecycle { destroy = true }` in `removed` block you might ask why this lifecycle needed?
The answer is that keeping a `removed` block with an explicit `lifecycle` block is good for documentation purposes in case you need to get back in history and see how infra looked before.
It does not say a lot of resoruce internals but holds its resource name how it was called.


### Tainting resources
"tainting" in Terraform is a way to mark a resource for recreation in the next plan. 
There are cases where a resource malfunctions even to make it works you may need to recreate it.
If you try to recreate a resource wth TF without tainting you would first remove the resource and then create it: remove config block -> apply -> put config back -> apply.
To make things done automatically you mark a resource for recreating and let TF recreate it.

`$ terraform taint <resource_type>.<resource_name>`   - mark/taint resource for recreation
`$ terraform apply`                                   - following taint, recreate the resource even if there;s no change in the config
`$ terraform untaint <resource_type>.<resource_name>` - removes taint from resource; runing terraform apply won't plan for a change

Example
```
resource "aws_s3_bucket" "tainted" {
  bucket = "my-tainted-bucket-19384981jhahds"
}
```
`terraform taint aws_s3_bucket.tainted`   - will taint S3 resource `aws_s3_bucket.tainted`
`terraform untaint aws_s3_bucket.tainted` - will remove taint from S3 resource `aws_s3_bucket.tainted`

For simple resource without dependencies tainting and recreating a resource is straght forward, but what happens when some resources depend on the other resource that you taint for recreation?
Example, you taint your vpc, and there's a lot of components like subnets, natgw, routing tables, etc that depend on the VPC resource. This all should be recreated.
```
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "this" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.0.0/24"
}
```
Create all resources and then taint the VPC `aws_vpc.this`.
`$ terraform taint aws_vpc.this`
This will kinda schedule the VPC for recreation and since new VPC will have a new Id, it should trigger subnet recreation as well.
Running `terraform apply` will dstroy 2 and add 2 resources. Basically it will destroy vpc and the subnet and recreate them from scratch. Subnet will be forced to be recreate as VPC will be new and with a new ID.

But this is not always the case. Some resources when they're recreated don;t trigger recreation of other resources that are tied to each other.
Example
```
resource "aws_s3_bucket" "tainted" {
  bucket = "my-tainted-bucket-19384981jhahds"
}

// add aws_s3_bucket_public_access_block to the same config
// by default buckets are private, which means all params in the resorucebelow are all true 
resource "aws_s3_bucket_public_access_block" "from_tainted" {
  bucket = aws_s3_bucket.tainted.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

```
`$ terraform apply` - to create `aws_s3_bucket_public_access_block.from_tainted` resource that lives in the same config as the S3 bucket we already created

Now taint S3 bucket
`$ terraform taint aws_s3_bucket.tainted` - taints S3 bucket and thus reschedules it for recreation

Run `$ terraform apply` - this will destroy `aws_s3_bucket.tainted` and create again
TF will not recreate the `aws_s3_bucket_public_access_block.from_tainted` because this resource already by default represents public access settings of the bucket 'my-tainted-bucket-19384981jhahds'.

Now modify aws_s3_bucket_public_access_block resource
```
resource "aws_s3_bucket_public_access_block" "from_tainted" {
  bucket = aws_s3_bucket.tainted.bucket

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```
After modifying public access block, untaint bucket
`$ terraform untaint aws_s3_bucket.tainted`

Run `terraform apply`- this will apply changes to `aws_s3_bucket_public_access_block` resource block.
If you check in aws console you'll see some bucket permisios are changed.

Taint the bucket again and run terraform apply.
`$ terraform taint aws_s3_bucket.tainted`
`$ terraform apply`

As a result TF will recreate the bucket that we tainted, but the thing is, the bucket will not have permissions from public access block applied.
Permissions in `aws_s3_bucket_public_access_block.from_tainted` are not taken into consideration.
Now if you run `teraform apply` again TF will detect the difference and will plan for changing th ebucket according publc access block resource in our config.

TF deprecated `taint` and recommends using `terraform apply -replace=""aws_s3_bucket.tainted` but this does not triger public access block resource recreation
You can specify `-replace` param twise to make TF repcreate bucket and the public access resource
`terraform apply -replace="aws_s3_bucket.tainted" -replace="aws_s3_bucket_public_access_block.from_tainted" ` which will recreate both resources


## Meta-arguments
Meta-arguments allow configuring Terraform behavior in many ways.

#### depends_on
Used to explicitly define dependencies between resources.
You have resource B that should be created only after resource A was created.

#### count, for_each
Allow the creation of multiple resources of the same type without having to declare separate resource blocks.

#### provider
Allows defining explicitly which provider to use with a specific resource.
This meta argument can be ued in any `resource` or `data` block.

#### path.root, path.module

### Lifecycle
The following attributes are part of `lifecycle` contruction of TF with its own purpose. 
- #### create_before_destroy
  Reverses the default replacement behavior so a new instance is created before the old one is destroyed.
  Prevents Terraform's default behavior of destroying before creating resources that cannot be updated in-place.
  The behavior is propagated to all resource's dependencies.
  BY default TF will destroy a resource and ten create a erplacement for it. For example we want to replace AMI of an existing EC2 instance.
  AWS does not allow doing that as it requires you to cretae a brand new EC2 instance with new AMI.
  TF default behavior would be to destroy the EC2 instnce in question and then create a replacemet for it.
  If `create_before_destroy` meta argument is set, TF will create a replacement resource before destroying the old exisint gone.

- #### replace_triggered_by
  Forces resource replacement when referenced items (like other resources or attributes) change.
  Replaces the resource when any of the referenced items change.

- #### prevent_destroy
  Causes Terraform to error if a plan would result in the resource's destruction.
  Terraform exits with an error if the planned changes would lead to the destruction of the resource marked with this.
  Protects a critical resource from being destroyed.
  If this meta argument is set, TF will fail at trying to destroy the resource protected by this argumnet.
  For example, you have an S3 bucket with creds or other critical information, you could protect it with this argument.
  If you remove this argument and your TF config requires replacing the resource, TF will destroy it.

- #### ignore_changes
  Instructs Terraform to disregard specific attribute updates after initial creation.
  We can provide a list of attributes that should not trigger an update when modified outside Terraform.

- ### precondition / postcondition
  Adds custom validation checks for resource operations.
  It's like a variable validation block but at the resource level.
  Example:
  ```
  resource "aws_subnet" "this" {
    for_each          = var.subnet_config
    vpc_id            = aws_vpc.this.id
    availability_zone = each.value.az
    cidr_block        = each.value.cidr_block

    tags = {
      Name   = each.key
    }

    lifecycle {
      precondition {
        condition     = contains(data.aws_availability_zones.available.names, each.value.az)
        error_message = "Invalid AZ."
      }
    }
  }
  ```

In the following example you see `aws_launch_configuration` LaunchConfiguration definition which is referenced by ASG.
The thing is, aws_launch_configuration is immutable and in case you add any change to it TF will try to delete it and replace it with another one.
And this is the standard behavior of TF. And here's a chicken-egg problem. Since the old LaunchConfig is used by the ASG, TF wont be able to remowe it and will fail.
To overcome the issue, this config uses `create_before_destroy` meta argument specified in `lifecycle` block.
This setting instructs TF to create a new LaunchConfig first, replace the reference to a new one i nthe ASG and then destroy the old LaunchConfig.
 
```
resource "aws_launch_configuration" "example" {
  image_id = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]
  user_data = <<-EOF
        #!/bin/bash
	echo "Hello, World" > index.xhtml
	nohup busybox httpd -f -p ${var.server_port} &
	EOF

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }
}
```


## path.root, path.module
In Terraform, these path variables are designed to solve one specific problem:
Relative paths break when you use modules.
1. The Core Concept
    `path.root`: Always points to the folder where you run terraform apply. Think of this as "The Project Home."
    `path.module`: Always points to the folder where the actual .tf file is located. Think of this as "The Current File’s Home."

2. Why is path.root often just '.' ?
   `path.root` often returns '.' However, '.' does not mean "where the module is."
    In Terraform, the "Current Working Directory" (CWD) is always the directory where you run the command.
    If you are in /home/user/project and run terraform apply, then '.' refers to /home/user/project.
    Even if Terraform is currently executing code inside a module located at /home/user/project/modules/network, the CWD remains the root.
    The Benefit: If you use `path.root`, you are telling Terraform: "Look for this file relative to where I started the command," no matter how deep the module is.

3. Example
Imagine this folder structure:
```
/my-project
├── main.tf           <-- (Root Module)
├── setup.sh          <-- (A global script)
└── /modules
    └── /s3_bucket
        ├── bucket.tf <-- (Child Module)
        └── policy.json <-- (A file specific to this module)
```
Scenario A: Accessing a Global File (Use path.root)
Inside modules/s3_bucket/bucket.tf, you want to upload the setup.sh file which is in the project root.
	# WRONG: This looks inside /modules/s3_bucket/
	source = "./setup.sh"

	# RIGHT: This looks in /my-project/
	source = "${path.root}/setup.sh"

Scenario B: Accessing a Module File (Use path.module)
Inside modules/s3_bucket/bucket.tf, you want to read policy.json located in the same folder as the module.
	# WRONG: This looks in /my-project/ (where you ran the command)
	policy = file("./policy.json")

	# RIGHT: This looks in /my-project/modules/s3_bucket/
	policy = file("${path.module}/policy.json")

4. How to get the Absolute Path
If you find the . confusing or if your script needs a full path (like /home/user/...), you should wrap the variable in the abspath() function:
	# This converts "." into the full, unambiguous system path
	`value = abspath(path.root)`


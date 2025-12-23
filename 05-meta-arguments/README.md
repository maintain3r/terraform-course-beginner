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

### Lifecycle
The following attributes are part of lifecycle contruction of TF with its own purpose. 
- #### create_before_destroy
  Prevents Terraform's default behavior of destroying before creating resources that cannot be updated in-place.
  The behavior is propagated to all resource's dependencies.
  BY default TF will destroy a resource and ten create a erplacement for it. For example we want to replace AMI of an existing EC2 instance.
  AWS does not allow doing that as it requires you to cretae a brand new EC2 instance with new AMI.
  TF default behavior would be to destroy the EC2 instnce in question and then create a replacemet for it.
  If `create_before_destroy` meta argument is set, TF will create a replacement resource before destroying the old exisint gone.

- #### replace_triggered_by
  Replaces the resource when any of the referenced items change.

- #### prevent_destroy
  Terraform exits with an error if the planned changes would lead to the destruction of the resource marked with this.
  Protects a critical resource from being destroyed.
  If this meta argument is set, TF will fail at trying to destroy the resource protected by this argumnet.
  For example, you have an S3 bucket with creds or other critical information, you could protect it with this argument.
  If you remove this argument and your TF config requires replacing the resource, TF will destroy it.

- #### ignore_changes
  We can provide a list of attributes that should not trigger an update when modified outside Terraform.


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

Datasources allow reading data about resources that already exist in the clouds.
For example you have a vpc module that was deployed manually or by Network Dept using a TF project (or manually) and you're working on a project that has another scope, for example database.
To run your database you need information like VPCId, subnets, etc. This all can be retrieved by TF using `data` construct.
It's worth noting that `data` construct has different params for each type of resource.
You can also use filter attribute of the data construct to reduce the scope of your search and get only what you need.

```
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Owner is Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```
In filter sections we see that keys "name" and "values" repeat multiple times.
In all cases 'name' corresponds to the name of the remote object's key/tag, where the values correspond to the value of the remote object's key.
In our example we filter only the items with:
```
name = "ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"
virtualization-type = hvm
```
As you an see, the value of a key can be even a regex.

For more info https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami

To reference the ami ID as in this example you have to start with 'data', like this:

```
output "ubuntu_ami" {
	value = data.aws_ami.ubuntu.id
}
```
or if it's an ec2 instance you want to create:
```
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  root_block_device {
    delete_on_termination = true
    volume_size           = 10
    volume_type           = "gp3"
  }
}
```

To get the data out of a data source, you use the following attribute reference syntax:
### data.<PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>
For example, to get the ID of the VPC from the aws_vpc data source, you would use the following: `data.aws_vpc.default.id`
You can combine this with another data source, aws_subnets, to look up the subnets within that VPC:
```
data "aws_vpc" "default" {
  default = true  checks for default vpc
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
```

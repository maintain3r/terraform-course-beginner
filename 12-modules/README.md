 ## Modules
Modules in Terraform allow you organize, encapsulate, and re-use Terraform components.
- Modules are used to combine different resources that are normally used together.
  They are just a collection of .tf files kept in the same directory.
  Simply speaking a module in terraform is simply a folder with terraform config files.

- Resources, variables, locals, data blocks of a module are not available to reference in Root module.
  To access a resource created by module, the module should explicitly have an `output` block exposing that resource

- Root module - the set of files in the main working directory. A working directory with *.tf files is an example of Root module.
- Root modules can then call other modules (child modules), defined either locally or remotely.
- The goal is to develop modules that can be reused in various ways.

What are benefit of using modules?
- Better configuration organization
  Group related parts of the infrastructure to make the code easier to understand and improve maintainability.

- Encapsulate configuration
  Encapsulate sets of resources to prevent unintended changes and mistakes that can happen in complex code bases.
  Module design and code complexity is hidden from a user using the module and providing an interface to a module allows avoiding any changes in the modules.

- Re-use configuration
  Modules make it much easier to reuse entire sets of components, thus improving consistency, saving time, and preventing errors.

- Ensure best practices
  Provide configuration and infrastructure best practices, and publish modules both publicly and privately for use by other teams.

## Standard Module Structure
A minimal module structure ercommended by TF contains the following components:
`main.tf`      - Main entry point for module resources. More complex modules should split the resources into multiple files with relevant names.
`outputs.tf`   - File containing all outputs from the module. Used by Terraform Registry to generate documentation.
`variables.tf` - File containing all variables for the module. Used by Terraform Registry to generate documentation.
`README.md`    - File containing documentation for the module. Used by Terraform Registry to generate documentation.

TF modules can be public and private.
`registry.terraform.io` - public registry
For private modules that are private to your company and shouldn't be publicly available use private registry provided by TF cloud.

### Module name is simply the name of th folder containing all module files.

A module ma have submodules which are folders with some other TF configs grouped together.
Submodule can be used by a module, which can be used by Root module.

You can specify `module` section as many as you need in your *.tf config files.
Example:
```
module "vpc" {
  source = "../../modules/vpc"


module "vpc_endpoints" {
  source = "../../modules/vpc-endpoints"
  vpc_id = module.vpc.vpc_id                   // this references vpc_id created in another module above 

```

There can be a case where you work on your project and want to use a submodule from a public source.
A submodule is basically a module that is nested into another higher level module.
To use a submodule of an external module you have to reference a module and the submodule living under the module by separating both paths by double slash `//`.
For example
```
module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
```
Using submodules allows you to use smaller pieces of a module independently.

### 1. Example of using aws vpc public module to create a vpc with our settings.
```
terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

// Use a data source to fetch the available availability zones for the specified region.
data "aws_availability_zones" "azs" {
  state = "available"
}

// here we use `module` with a name we want, it can be anything, and pass some params explicitly
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.3"

  cidr            = "10.0.0.0/16"
  name            = "12-public-modules"
  azs             = data.aws_availability_zones.azs.names
  private_subnets = ["10.0.0.0/24"]
  public_subnets  = ["10.0.128.0/24"]
}
```
Every time you add a module to your project (root module) you have to run `terraform init` to initialize TF and let it fetch the modules.
You'll see a `modules` folder under `.terraform` folder which will contain the module(s) name(s) you downloaded.
Most probably the code you'll under the module you downloaded will be a githuib code with the same structure as on module github page.
A module you use in you project can have its own `required_providers` section and it should not conflict with the same instruction in your project/root module.
The constraints you put in root module should not conflict with consraints that are set in the module.
Fro example if your root project has `version = "5.0.0"` for aws provider and module has version "5.4.1" the TF will throw an error.

### 2. Extends the previous example and creates an EC2 iunstance i a vpc created above
```
// shared_data.tf
locals {
  project_name = "12-public-modules"
}

// networking.tf
locals {
  vpc_cidr             = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.0.0/24"]
  public_subnet_cidrs  = ["10.0.128.0/24"]
}

data "aws_availability_zones" "azs" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.3"

  cidr            = local.vpc_cidr
  name            = local.project_name
  azs             = data.aws_availability_zones.azs.names
  private_subnets = local.private_subnet_cidrs
  public_subnets  = local.public_subnet_cidrs
}

locals {
  project_name = "12-public-modules"
  common_tags = {
    Project   = local.project_name
    ManagedBy = "Terraform"
  }
}

locals {
  instance_type = "t2.micro"
}

// get the latest ubuntu22 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  name                   = local.project_name
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = local.instance_type
  vpc_security_group_ids = [module.vpc.default_security_group_id]  - reference `default_security_group_id` `output` created in the vpc module
  subnet_id              = module.vpc.public_subnets[0]            - reference `public_subnets` `output` creted within vpc module
  tags = local.common_tags
}
```

As you can see, referencing a module is the same as referencing a `data` block.
E.g. data.resource.ref-name
     module.module-name.resoruce
You can still use `for_each` or `count` meta arguments within the module you use.


## Building your own modules
### When to create modules and which best practices to follow?
- Creating a module is as simple as creating a directory and a couple of terraform files within that directory.
- When to build modules?
  - When useful abstractions of our infrastructure can be identified.
  - When certain groups of resources always need to be created together and strongly depend on each other.
  - When hiding the infrastructure details of a certain part of our infrastructure will lead to better developer experience.
- Which best practices to follow?
  - Use object attributes: group related information under object-typed variables.
  - Separate long-lived from short-lived infrastructure: resources that change rarely should not be grouped together with resources that change often.
  - Do not try to cover every edge case: this can quickly lead to highly complex modules, which are difficult to maintain and configure.
    Modules should be reusable blocks of infrastructure, and catering to edge cases goes against that purpose.
  - Support only the necessary configuration variables: do not expose all the internals of the module for configuration via variables.
    This hurts encapsulation and makes the module harder to work with.
- Which best practices to follow?
  - Output as much information as possible: even if there is no clear use for some information, providing it as an output will make the module easier to use in future scenarios.
  - Define a stable input and output interface: All used variables and outputs create coupling to the module.
    The more coupling, the harder it is to change the interface without breaking changes. Keep this in mind when designing the module's interface.
  - Extensively document variables and outputs: this helps the module's users to quickly understand the module's interface and to work more effectively with it.
  - Favor a flat and composable module structure instead of deeply nested modules: deeply nested modules become harder to maintain over time and increase the configuration complexity for the module's users.
  - Make assumptions and guarantees explicit via custom conditions: do not rely on the users always passing valid input values.
    Thoroughly validate the infrastructure created by the module to ensure it complies with the requirements the module must fulfill.
  - Make a module's dependencies explicit via input variables: data sources can be used to retrieve information a module needs, but they create implicit dependencies,
    which are much harder to identify and understand. Opt for making these dependencies explicit by requiring the information via input variables.
  - Keep a module's scope narrow: do not try to do everything inside a single module.

#### Example of module created locally 
Here's an example of a project structure with `modules` dir containing the `networking` dir which will contain all module files.
The module follows the same best practices mentioned above.
When you write the `module` block in your root project it does not have to be the same name as the project containing the module files.
You can call it however you want, the importatn part is the `source` directive that specifies the directory containing the module files.
You can treat the module name in the `module` block in your root project dir as reference name. 
dns_project/
├── compute.tf
├── modules
│   └── networking
│       ├── examples
│       │   └── complete
│       │       └── main.tf
│       ├── LICENSE
│       ├── outputs.tf
│       ├── providers.tf
│       ├── README.md
│       ├── variables.tf
│       └── vpc.tf
├── networking.tf
├── outputs.tf
├── providers.tf
└── README.md

For all variables defined in the module you should pass a value from the project using the module.
The only exception of not passing a value is the default value speciied for the variable block in the module.
Simply speaking, if your module has a variable called `vpc_config` you'll pass it a value within the `module` block of your project using the module.
Remember, each time you add a new module you must run `terraform init` cmd.

### Module outputs.
While you run terraform plan/apply you won;t see all outputs of the module in your root terraform project.
If you still want to access/print an output section of a module you can reference that output in your project's output block.
```
Example:
// vpc module output section
output "public_subnets" {
  value = local.public_subnets
}

// terraform project having `module "vpc"` block
output "module_public_subnets" {
  value = module.vpc.public_subnets   // we're accessing the output 'public_subnets' of the vpc module
}
```


### Publishing Modules
Make your Terraform module available to others via Terraform Registry
- Anyone can publish a module, as long as the following conditions are met:
  - The module must be on GitHub and must be a public repo. This is required only for using the public registry; for private ones, this can be ignored.
  - Repositories must use a naming format: terraform-<PROVIDER>-<NAME>, where PROVIDER is the provider where resources are created, and NAME is the type of infrastructure managed by the module.
  - The module repository must have a description, which is used to populate the short description of the module. This should be a simple one sentence description of the module.
  - The module should adhere to the standard module structure (main.tf, outputs.tf, variables.tf). The registry uses this information to inspect the module and generate documentation.
  - Uses x.y.z tags for releases. The registry uses these tags to identify module versions. Release tag names must be a semantic version, and can be optionally prefixed with a "v".
- Published modules support versioning, automatically generate documentation, allow browsing version histories, show examples and READMEs, and more.

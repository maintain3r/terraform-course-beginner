### Backend
Backends define where Terraform stores its state file
- There are multiple types of backends, which can be place into three categories:
  - Local: the state file is stored in the user's local machine.
  - Terraform Cloud: the state file is stored in Terraform Cloud. Offers additional features.
  - Third-party remote backends: the state file is stored in a remote backend different from Terraform Cloud (for example S3, Google Cloud Storage, Azure Resource Manager / Blob Storage, among others).
- Different backends can offer different functionalities  and require different arguments.
- A Terraform configuration can provide only one backend.
- The backend block cannot use any input variables, resource references, and data sources.
- Remote backends require authentication credentials in order for Terraform to properly access the files.
- When changes are made to the configured backend, we must rerun the terraform init command.
- Terraform offers the possibility of migrating state between different backends.


Terraform uses persisted state data to keep track of the resources it manages.
This data can be stored in Hashicorp cloud or in other supported types of backends.
By default TF uses local backend type which does not require any configurations.
To store TF state files in a remote location like AWS S3 bucket define s3 type `backend` configuration within `terraform` section of your terraform file.
Only one backend for the entire project can be used.
The backend config is stored under .terraform/terraform.tfstate file. This file does not contain any states or simply speaking it does contain any objects of your infra.
However it contains configuration of your backend which might have something you shouldn't expose like the bucket name, the key (state file name), aws region where the S3 bucket is located.
For this, you should configure your backend with empty parameters in the *.tf file and then pass a config file that contains all aguments and their values to `terraform init` command.

### Backend arguments
The arguments in the backend block body are specific to the backend type. 
They specify where and how the backend stores configuration state. 
Some backend types allow you to configure additional behaviors. Refer to the documentation for your backend for additional information.
Some backends allow you to provide access credentials as part of the configuration, but it's not recommended including access credentials directly in the configuration.
Instead, leave credential-related arguments unset and provide them using the credentials files or environment variables that are conventional for the target system.

### Credentials and sensitive data
Backends store state in a remote service, which allows multiple people to access it.
Accessing remote state generally requires access credentials, since state data contains extremely sensitive information.

Warning: It's recommended using environment variables to supply credentials and other sensitive data. If you use `-backend-config` or hardcode these values directly in your configuration,
Terraform will include these values in both the .terraform subdirectory and in plan files. This can leak sensitive credentials.

Terraform writes the backend configuration in plain text in two separate files.
- The `.terraform/terraform.tfstate` file contains the backend configuration for the current working directory.
- All plan files, like `terraform plan -out myplan` capture the information in `.terraform/terraform.tfstate` at the time the plan was created!
  This helps ensure Terraform is applying the plan to correct set of infrastructure.

NOTE: When applying a plan that you previously saved to a file, Terraform uses the backend configuration stored in that file instead of the current backend settings.
If that configuration contains time-limited credentials, they may expire before you finish applying the plan.
Use environment variables to pass credentials when you need to use different values between the plan and apply steps.

### Initialize the backend
When you change a backend's configuration, you must run terraform init again to validate and configure the backend before you can perform any plans, applies, or state operations.
After you initialize, Terraform creates a `.terraform/` directory locally. This directory contains the most recent backend configuration, including any authentication parameters you provided to the Terraform CLI.
Do not check this directory into Git, as it may contain sensitive credentials for your remote backend!
The `local` backend configuration is different and entirely separate from the `terraform.tfstate` file that contains "state" data about your real-world infrastructure.
Terraform stores the `terraform.tfstate` file in your remote backend. When you change backends, Terraform gives you the option to migrate your state to the new backend.
This lets you adopt backends without losing any existing state.
Important: Before migrating to a new backend, manually back up your state by copying your `terraform.tfstate` file to another location.

### Partial configuration methods
File:
You do not need to specify every required argument in the backend configuration.
Omitting certain arguments may be desirable if some arguments are provided automatically by an automation script running Terraform. When some or all of the arguments are omitted, it'scalled partial configuration.

Here's an example of passing a file with all arguments neede by backend block.
```
cat  state.tf
terraform {
  backend "s3" {
    bucket = "" 
    key    = ""
    region = ""
    profile= ""
  }
}

```

Suggested naming convention for backend configs is 'config.backend name.tfbackend.
```
cat config.s3.tfbackend

bucket = "your-bucket-name" 
key    = "dev/terraform.tfstate"
region = "us-east-1"
profile= "your_aws_profile"
```

Rrun TF init supplying backend config from a file
You can add `-migrate-state` arg to this cmd to migrate state file from the current backed location to remote, so that your s3 bucket gets the information that's currently known to TF.
$ `terraform init -backend-config="./config.s3.tfbackend"`

Command-line key/value pairs:
Key/value pairs can be specified via the init command line. 
Note that many shells retain command-line flags in a history file, so this isn't recommended for secrets. 
To specify a single key/value pair, use the -backend-config="KEY=VALUE" option when running terraform init.

Interactively:
Terraform will interactively ask you for the required values, unless interactive input is disabled. Terraform will not prompt for optional values.

If backend settings are provided in multiple locations, the top-level settings are merged such that any command-line options override the settings in the main configuration and then 
the command-line options are processed in order, with later options overriding values set by earlier options.
The final, merged configuration is stored on disk in the .terraform directory, which should be ignored from version control. 
This means that sensitive information can be omitted from version control, but it will be present in plain text on local disk when running Terraform.
When using partial configuration, Terraform requires at a minimum that an empty backend configuration is specified in one of the root Terraform configuration files, to specify the backend type. 
For example:

```
terraform {
  backend "consul" {}
}
```

File
A backend configuration file has the contents of the backend block as top-level attributes, without the need to wrap it in another terraform or backend block:

```
address = "demo.consul.io"
path    = "example_app/terraform_state"
scheme  = "https"
```

*.backendname.tfbackend (e.g. config.consul.tfbackend) is the recommended naming pattern. Terraform will not prevent you from using other names but following this convention will help your editor understand the content and likely provide better editing experience as a result.
Command-line key/value pairs

The same settings can alternatively be specified on the command line as follows:
```
$ terraform init \
    -backend-config="address=demo.consul.io" \
    -backend-config="path=example_app/terraform_state" \
    -backend-config="scheme=https"
```
The Consul backend also requires a Consul access token. 
Per the recommendation above of omitting credentials from the configuration and using other mechanisms, the Consul token would be provided by setting either the CONSUL_HTTP_TOKEN or CONSUL_HTTP_AUTH environment variables. 
See the documentation of your chosen backend to learn how to provide credentials to it outside of its main configuration.

Change configuration
You can change your backend configuration at any time. 
You can change both the configuration itself as well as the type of backend (for example from "consul" to "s3").
Terraform will automatically detect any changes in your configuration and request a reinitialization. As part of the reinitialization process, 
Terraform will ask if you'd like to migrate your existing state to the new configuration. This allows you to easily switch from one backend to another.


Now let's look at an example.
You create a TF file with some instuctions in it:
```
$ cat /tmp/TF/random.tf 
terraform {
  required_version = "~> 1.7"

  required_providers {
    random = {
      version = "~> 3.0"
      source  = "hashicorp/random"
    }
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 100
}

output "bucket_name" {
  value = "creds-${random_id.bucket_suffix.b64_std}"
}
```
By default TF works with local backend if otherwise isn't specified. 

$ terraform plan
This will check all your *.tf files in your working dir (in this case random.tf) and create a plan of what needs to be done.
As it was said above, the plan will also contain the backend config so that TF knows where to save the information about the latest state of your infra regardless of what backend is the most recent.
This means that TF does not use the most recent config of the backend you configured after the terraform plan command, it uses the one that was known at the moment the plan was created.
In this case, you can even create a plan and store it in a different file that you may want to execute later after checking everything it plans to change in your infra.
$ `terraform plan -out myplan` will create a plan file and store everything it wants to change in your infra. Also, it will add  backend configuration at the time of creating this plan into the same file myplan.

You can check what TF wants to modify in your infra before you actually apply it.
$ `terraform show myplan` shows the content of myplan file (you can't just open it using smth like "cat" cmd, as it's a bin format_.
$ `terraform apply myplan` will apply your plan
                           
Let's say we run terraform plan and then apply to create what we need.
TF will create .terraform/terraform.tfstate to store the current backend configuration and for the state about the infra it will create a file terraform.tfstate in the working dir.
```
$ ls -la /tmp/TF/
.terraform
random.tf
terraform.tfstate
```

Now let's add loca type backed config explicitly specifying the path argument of it.
We'll add backend section with empty path argument in random.tf file and create a config file with path and value.
```
$ cat /tmp/TF/random.tf 
terraform {
  required_version = "~> 1.7"

  required_providers {
    random = {
      version = "~> 3.0"
      source  = "hashicorp/random"
    }
  }

  backend "local" {
    path = ""
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 100
}

output "bucket_name" {
  value = "creds-${random_id.bucket_suffix.b64_std}"
}

cat /tmp/TF/config.local.tfbackend 
path="aaa.tfstate"
```

$ terraform init -backend-config="config.local.tfbackend" - will configure local backend so that it store TF state files in aaa.tfstate file.
The new config of local backend will be saved in the .terraform/tfstate file.

If there was a state file with data in it TF will ask if you want to migrate the current state data into the new location/file.
$ terraform init -backend-config="config.local.tfbackend" -migrate-state - will migrate state data from the last known state file which in our case terraform.tfstate into aaa.tfstate.

But imagine you didn't specify -migrate-state argument and only updated the backed config.
TF will update the .terraform/terraform.tfstate file with the new settings but there will be no aaa.tfstate file created.
If you ask TF to show you what it knows abouit your infra by running `terraform state list` it's gonna complain that it has no state.
Remember, you didn't migrate yoru state data from the previous state file.
Now if you apply the plan file 'myplan' you generated earlier:
$ `teraform apply myplan` TF will apply this plan and update terraform.tfstate file since this setting was burned into myplan file. 
Remember TF backend config was pointing to terraform.tfstate file when we generated myplan file.
There will be no aaa.tfstate file generated in the workign dir, since we aplied a pan that didn't know anythign about aaa.tstate. We reconfigured our local backend after we created myplan plan.

This is a result of you not migrating the current state after modifying the backend and initializing TF. SImply speakign you didn;t specify '-migrate-state' option.
What TF knows about the state - nothing, as aaa.tfstate doe snot exist in workin dir even if backend configuration (.terraform/tfstate) says that the state file is aaa.tfstate.
If you run `terraform plan` and then `teraform appl` TF will generate a plan based on random.tf and apply it.
Once applied, you'll see your changes and the file aaa.tfstate will be generated.

Backend and TF state file should be consistent, pay attention to that, especially when you migrate from one backend to another.
Some times it may require you to perform a manual state file transition.

And finally, locking.
In order to avoid any chaos working with TF in a team where multiple people want to sbmit their changes, TF has a locking mechanism built in.
This prevents bad things from happennign like state file inconsistency, corruption or mess in the infra.
The recent version of S3 backend implementation allows you to specify a bool parameter that if is set to `true` will create a lock file in you s3 bucket when a user runs terraform plan cmd.
Only after user executes its plan, TF will remove the locking file which will allow next user to plan and apply his changes. So, really useful.

### Terraform State
- State is always required in Terraform.
- Important! The state contains extremely sensitive data, so be careful regarding who has access to it.
- The state file also stores metadata, such as resource dependencies, so that Terraform knows in which order resources must be created, updated or deleted.
- Before any planning operation, Terraform refreshes the state with the information from the respective real-world objects.
  This is essential to avoid configuration drift. If a real-world object has been modified outside of Terraform and the respective configuration has not been updated, TF will revert the changes made manually.
- State can be either stored locally (default) or in several remote backends (S3, Google Cloud Storage, Terraform Cloud, among others).
- State locking: locks the state while executing write operations to prevent concurrent modifications and state corruption.

## Workspaces
### Use a single code-base for different environments
- Workspaces allow us to leverage the same configuration directory to create different environments.
  - As a result, we can reduce code duplication and avoid installing multiple copies of modules and providers.
- When using the CLI in a workspace, resources from other workspaces are not considered.
- Different workspaces correspond to different state data. Terraform stores them in different `.tfstate` files.
- Terraform always has at least one workspace called `default`.
  - The default workspace is created when we initialize the Terraform project.
  - It is used by default when we do not specify any other workspace.
- Most, but not every, remote backend support workspaces.
- We can use terraform.workspace to access the current workspace, and change options based on the selected workspace.
  - Recommendation: do not use terraform.workspace for conditional operations. Instead, receive the information via variables.
- This is different from Terraform Cloud's workspaces.

Workspaces in TF allow creating resources in different environments using the same project code.
This is achieved by storing each environment's `*.tfstate` file in differen localtions.
By default even if there's no workspace created TF works with `default` workpace, which keeps it's terraform.tfstate file in the root of the project.
```
$ terraform workspace
Subcommands:
    delete    Delete a workspace
    list      List Workspaces
    new       Create a new workspace
    select    Select a workspace
    show      Show the name of the current workspace
```
Create a separate workspace for dev environment will look like this:
`terraform workspace new dev` - this will create a separate workspace for dev infra and will switch into it at the same time
So far there's no tfstate file yet, but if you run `terraform apply` TF will dpeloy resources and will create a directory
`terraform.tfstate.d/dev` and will put terraform.tfstate file under dev folder storing the state information about resources in dev environment.
For every new workspace TF will add a new subfolder under `terraform.tfstate.d/` and will also create a terraform.tfstate in it.

### `terraform.workspace` - is a special meta argument which stores the name of the name of the workspace you're currently in.
You can interpolate this argument and make it part of your resource name (not the referenec name that goes next to resource type).
For example if you create an S3 bucket you can make `terraform.workspace` part of you bucket name like this:
```
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "this" {
  bucket = "workspaces-demo-${terraform.workspace}-${random_id.bucket_suffix.hex}"
}
```
If you have workspaces dev and default (which is by default) this will name your bucket `workspaces-demo-default-<some hex from random resource>` and `workspaces-demo-dev-<some hex from random resource>`.

Let's explore how not to use the value from terraform.workspace in our Terraform configuration.
For that, let’s first create two more workspaces: prod and staging.
Now extend the S3 bucket configuration to deploy multiple buckets based on the following rules:
    3 buckets should be deployed in the prod workspace.
    2 buckets should be deployed in the staging workspace.
    1 bucket should be deployed in the dev workspace.

We also need to add the count.index value to the bucket name so that it is unique. Here is how not to use terraform.workspace!
```
resource "aws_s3_bucket" "this" {
  count  = terraform.workspace == "prod" ? 3 : terraform.workspace == "staging" ? 2 : 1
  bucket = "workspaces-demo-${terraform.workspace}-${count.index}-${random_id.bucket_suffix.hex}"
}
```
If you keep adding workspace your ternary condition in resource `count` argument will be very hard to maintain.
Although this works, the code above is very difficult to read and maintain.

There is a much better way of doing that.
You need to create different `.tfvars` files for different workspaces which will store your variable value for each specific workspace.
The filename must be the same as the workspace name followed by .tfvars

Example:
1. Define a new variable `bucket_count` of type number, which will receive the count of buckets we should deploy.
```
$ cat variables.tf
variable "bucket_count" {
  type = number
  description = "Number of buckets to create"
}

2. Create three `.tfvars` files, each one for a workspace. 
Make sure that the name of the file matches `<workspace name>.tfvars. 
Define the variable in each file with the correct number of buckets we would like to deploy per workspace.
```
# dev.tfvars
bucket_count = 1

# staging.tfvars
bucket_count = 2

# prod.tfvars
bucket_count = 3
```

Run `terraform apply -var-file=$(terraform workspace show).tfvars`, which will leverage the current workspace to find the correct .tfvars file.
You can create a Bash alias to this command to make your life easier, since the command remains the same independently of the selected workspace.
`alias tfapply='terraform apply -var-file=$(terraform workspace show).tfvars'`
then you can simply run tapply and TF will run with proper .tfvars file thanks to `$(terraform workspace show).tfvars` as value for `-var-file` cli argument.

```
resource "aws_s3_bucket" "this" {
  count  = var.bucket_count
  bucket = "workspaces-demo-${terraform.workspace}-${count.index}-${random_id.bucket_suffix.hex}"
}
```
As you can see, with this approach we can easily extend our configuration without having to touch the underlying Terraform code.
If you don't want to use `terraform workspace select <environment>` you can set environment vaiable TF_WORKSPACE like so
export TF_WORKSPACE=dev
`terraorm workspace show`
dev - returns dev environment set by env variable

NOTE, in this case if you try changnig the workspace by running `terraform workspace staging` TF will throw an error saying,
that the current workspace is set to dev as it comes from the env variable TF_WORKSPACE.
It will suggest to unset the TF_WORKSPACE variable or to give it another name.
Setting TF_WORKSPACE takes precedence over `terraform workspace select` and can be used in CI/CD environment whenever we want to set the workspace via environment variable.

If you try to remove a workspace that has resource in it using `terraform workspace delete <workspace name>` TF will fail,
but it you pass `-force` argument it will remove the workspace even if with resuorces in it.

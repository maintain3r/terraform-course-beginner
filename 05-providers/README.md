### Providers
Providers are how Terraform interacts with remote APIs and platforms
- Each provider adds a set of resource types and data sources that the Terraform project can use.
- Providers are developed and maintained separately from Terraform. They fit into Terraform's plugin architecture.
- The Terraform configuration must declare all the providers it requires.
- Provider configurations belong to the root module of a Terraform project. Child modules receive their provider configuration from the parent module.
- We can use the same version constraints as when specifying the Terraform version, and we can create a dependency lock file to ensure that the exact versions of providers are installed.

Same provider can be declared in multiple times.
To make a distinction between them you use `alias` parameter within provider block.
The povider without an alias will be used as default provider for this specific type.
This is useful when you have to create resuorces in different regions in the same TF project.
Let's see an example where we specify the same provider multiple times and create a bucket in different aws regions.

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

This provider will be the default among all aws providers, there's no alias set

provider "aws" {
  region = "eu-west-1"
}

Configure another instance of the aws provider by adding another provider block and setting the region to us-east-1. 

Also assign it an alias so that it can be later used with resources
provider "aws" {
  region = "us-east-1"
  alias  = "us-east"
}

Create an S3 bucket resource in the eu-west-1 region:

resource "aws_s3_bucket" "eu_west_1" {
  bucket = "some-random-bucket-name-eu_west-1"
}

Create another S3 bucket resource in the us-east-1 region.
Use alias to specify the nono-default provider and pass it to the provider argument of the resource

resource "aws_s3_bucket" "us_east_1" {
  bucket   = "some-random-bucket-name-us-east-1"
  provider = aws.us-east
}

```

In this example terraform version and aws provider versions have specific constraints specified.
To see TF version and all the versions of all providers used in your project use
$ terraform version

While we specify a version using smth like version = "~> 5.0", terraform version cmd will show us the actual version it downloaded from TF cloud.
Of course it has to follow the limitations specified in the version param.
If we wan to upgrade or downgrade a provider or terraform version we can use
$ terraform init -upgrate

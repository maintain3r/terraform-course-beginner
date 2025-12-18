terraform {
  required_version = "~> 1.7"  # sets terraform version sets provider version to be 5.0 and anything higher on the most right number; i.e. 2.0 won't work
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"       # sets provider version to be 5.0 and anything higher on the most right number; i.e. 6.0 won't work
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"       # sets provider version to be 3.0 and anything higher on the most right number; i.e. 4.0 won't work
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# For version constraints you can use
# >, >=
# <, <=
# ~>

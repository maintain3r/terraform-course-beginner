terraform {
  required_version = "~> 1.7"

  required_providers {
    random = {
      source = "hashicorp/random"
    }
  }
}

variable "prefix" {
  description = "What is the prefix value to use with randomizer?"
  type        = string
  default     = "Perpey"
}

locals {
  byte_length = 10
  suffix      = "my-custom-suffix"
}

resource "random_id" "randomizer" {
  byte_length = 6
}

resource "random_id" "mixer" {
  byte_length = local.byte_length
}

resource "random_id" "resource_depends_on_mixer" {
  byte_length = length(random_id.mixer.id)
  prefix      = "DEPENDENCY-"
}


output "out_randomizer" {
  value = "${var.prefix}-${random_id.randomizer.hex}"
}

output "out_mixer" {
  value = "${random_id.mixer.hex}-${local.suffix}"
}

output "resource_depends_on_mixer" {
  description = "Here's the output of resource_depends_on_mixer resource in HEX"
  value = random_id.resource_depends_on_mixer.hex
}

output "resource_depends_on_mixer_same" {
  description = "Here's the output of resource_depends_on_mixer as the one above"
  value = random_id.resource_depends_on_mixer.hex
}

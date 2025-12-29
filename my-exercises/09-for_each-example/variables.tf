locals {
  tier_rules = {
    golden = { min = 5, max = 10 }
    silver = { min = 3, max = 8 }
    bronze = { min = 1, max = 5 }
  }
}

variable "mixer_config_tiers" {
  description = "Contains mixer configs for each type of mixer tier."
  type = object({
    golden = object({
      prefix      = string
      byte_length = number
    }),
    silver = object({
      prefix      = string
      byte_length = number
    }),
    bronze = object({
      prefix      = string
      byte_length = number
    })

  })

  # check if tier name is one of the alloved: golden, silver, bronze
  validation {
    condition     = alltrue([for tier in keys(var.mixer_config_tiers) : contains(["golden", "silver", "bronze"], tier)])
    error_message = "Only golden, silver, bronze tiers are supported."
  }
  # check wether each tier has correct prefix and byte_length arguments according to tier name
  validation {
    condition = alltrue([for tier in ["golden", "silver", "bronze"] : var.mixer_config_tiers[tier].prefix == tier &&
      var.mixer_config_tiers[tier].byte_length >= local.tier_rules[tier].min &&
    var.mixer_config_tiers[tier].byte_length <= local.tier_rules[tier].max])
    error_message = "Tier prefix must match tier name and byte_length must be within allowed range"
  }
}

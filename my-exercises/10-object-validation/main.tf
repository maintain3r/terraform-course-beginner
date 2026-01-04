locals {
  allowed_prefix_names = ["golden", "silver", "bronze"]
  mixer_tier_min_value = {
    golden = 8,
    silver = 5,
    bronze = 1
  }
}

resource "random_id" "mixer" {
  byte_length = var.mixer_config.byte_length
  prefix      = var.mixer_config.prefix

  lifecycle {
    precondition {
      condition     = var.mixer_config.byte_length > 0 && var.mixer_config.byte_length <= 10
      error_message = "Mixer config byte_length is out of range of allowed values between 1..10 inclusive"
    }

    postcondition {
      # using `self.prefix` we reference prefix field of the object we're in - `random_id.mixer`
      condition     = contains(local.allowed_prefix_names, self.prefix)
      error_message = "Prefix name should be one of the allowed values: golden, silver, bronze"
    }
  }
}

check "too_small_mixer_byte_length_check" {
  assert {
    condition = alltrue([random_id.mixer.byte_length >= local.mixer_tier_min_value[random_id.mixer.prefix]])
    error_message = "Mixer byte_length is too small for ${upper(random_id.mixer.prefix)} tier"
  }
}

variable "mixer_configs" {
  type = list(object(
    {
      byte_length = number,
      prefix      = string
    }
  ))
  description = "Contains mixer settings"

  # check if prefix is set to  advanced_mixer or basic_mixer
  validation {
    condition     = alltrue([for item in var.mixer_configs : contains(["basic_mixer", "advanced_mixer"], item.prefix)])
    error_message = "Allowed values for prefix are advanced_mixer or basic_mixer"
  }

  # cehck it byte_length is no more than 10
  validation {
    condition     = alltrue([for item in var.mixer_configs : item.byte_length > 0 && item.byte_length <= 10])
    error_message = "Allowed values for byte_length are 1..10"
  }
}

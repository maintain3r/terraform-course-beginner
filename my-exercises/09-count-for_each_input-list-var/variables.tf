variable "mixer_configs" {
  type = list(object(
    {
      byte_length = number,
      prefix      = string
    }
  ))
  description = "Contains mixer settings"
}

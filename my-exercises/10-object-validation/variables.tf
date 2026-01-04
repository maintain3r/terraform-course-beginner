variable "mixer_config" {
  description = "Defines mixer configuration"
  type = object({
    byte_length = number
    prefix      = string
  })
}

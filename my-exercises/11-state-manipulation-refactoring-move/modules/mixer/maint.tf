resource "random_id" "moduled_mixer" {
  for_each = toset(var.mixer_names)
  byte_length = 5
#  prefix = each.value
  prefix = "mixer"
}

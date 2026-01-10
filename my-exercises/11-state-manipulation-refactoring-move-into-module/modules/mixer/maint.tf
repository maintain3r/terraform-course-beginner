resource "random_id" "moduled_mixer" {
  for_each = toset(var.mixer_names)
  byte_length = 5
#  prefix = each.value
  prefix = "mixer"
}

output "path_built_in_variables" {
  value = {
    path_root   = path.root
    path_module = path.module
  }
}

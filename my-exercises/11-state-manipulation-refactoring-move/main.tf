locals {
  mixer_names = ["golden", "silver", "bronze"]
}

#Elements before moving: random_id.randomizer["golden"]; random_id.randomizer["golden"]; random_id.randomizer["golden"]
# elements created by this resource block
#
#$ terraform state list
# random_id.randomizer["bronze"]
# random_id.randomizer["golden"]
# random_id.randomizer["silver"]
#
# resource "random_id" "randomizer" {
#   for_each = toset(local.mixer_names)
#   byte_length = 5
#   prefix = "mixer"
# }


# Move each element specifying it separately in each moved block
# or use a sngle moved block with all elements in it
# moved {
#  from = random_id.randomizer
#  to   = module.mixer.random_id.moduled_mixer
#}
#
# NOTE: elements' keys in module MUST be the same as the ones initially created in this root module

#moved {
#  from = random_id.randomizer["golden"]
#  to   = module.mixer.random_id.moduled_mixer["golden"]
#}

#moved {
#  from = random_id.randomizer["silver"]
#  to   = module.mixer.random_id.moduled_mixer["silver"]
#}

#moved {
#  from = random_id.randomizer["bronze"]
#  to   = module.mixer.random_id.moduled_mixer["bronze"]
#}

# Moving all resources from this root module to modules/mixer with one single move block at once
moved {
  from = random_id.randomizer
  to   = module.mixer.random_id.moduled_mixer
}

module "mixer" {
  source = "./modules/mixer"
  mixer_names = local.mixer_names  
}

output "path_built_in_variables_module_view" {
  value =  module.mixer.path_built_in_variables
}

output "path_built_in_variables_root_module_view" {
  value = {
    # how root module sees it
    path_root   = path.root
    path_module = path.module
    absolute_root_path = abspath(path.root)
    absolute_module_path = abspath(path.module)

    # how module sees it
    module_path_root            = module.mixer.path_built_in_variables.path_root
    module_path_module          = module.mixer.path_built_in_variables.path_module
    module_absolute_path_root   = abspath(module.mixer.path_built_in_variables.path_root)
    module_absolute_path_module = abspath(module.mixer.path_built_in_variables.path_module)
  }
}

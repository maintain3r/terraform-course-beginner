locals {
  mixer_config = {
    byte_length = 5
    prefix      = "mixer"
  }
}

resource "random_id" "remaining_mixer_after_forgetting_all_mixers" {
  byte_length = local.mixer_config.byte_length
  prefix      = local.mixer_config.prefix
}

#resource "random_id" "mixer" {
#  count       = 2
#  byte_length = local.mixer_config.byte_length
#  prefix      = "${local.mixer_config.prefix}_${count.index}"
#}

removed {
  from = random_id.mixer

  lifecycle {
    destroy = false
  }
}

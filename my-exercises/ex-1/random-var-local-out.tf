variable "prefix" {
	type = string
	default = "Perpey"
	description = "Use this previx variable with random id randomizer"
}

locals {
	byte_length = 10
	suffix = "my-custom-suffix"
}

resource "random_id" "randomizer" {
	byte_length = 6
}

resource "random_id" "mixer" {
        byte_length = local.byte_length
}

output "out_randomizer" {
	value = "${var.prefix}-${random_id.randomizer.hex}"
}

output "out_mixer" {
	value = "${random_id.mixer.hex}-${local.suffix}"
}

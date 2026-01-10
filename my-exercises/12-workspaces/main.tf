resource "random_id" "mixer" {
  byte_length = var.byte_length
  prefix      = "${var.prefix}-${terraform.workspace}"
}

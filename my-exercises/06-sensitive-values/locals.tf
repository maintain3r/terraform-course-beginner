locals {
  security_api_token = var.api_token
}

locals {
  common_tags = {
    service  = "Infra"
    provider = "AWS"
    bu       = "Coveo"
  }
}

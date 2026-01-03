variable "subnet_config" {
  type = map(object({
    cidr_block = string
    public     = optional(bool, false)
    az         = string
  }))

  validation {
    condition = alltrue([
      for config in values(var.subnet_config) : can(cidrnetmask(config.cidr_block))
    ])
    error_message = "The cidr_block config option must contain a valid CIDR block."
  }
}

locals {
  public_subnets = { for k, v in var.subnet_config : k => v if v.public }
  private_subnets = { for k, v in var.subnet_config : k => v if !v.public }
}

output "subnet_config" {
  value = var.subnet_config
}

output "public_subnets" {
  value = local.public_subnets
}

output "private_subnets" { 
  value = local.private_subnets
}

output "subnet_by_access_type" {
  value = {
    public_subnets = [ for item in values(var.subnet_config) : item.cidr_block if item.public ]
    private_subnets = [ for item in values(var.subnet_config) : item.cidr_block if !item.public ]
  }
}

variable "location" {
  description = "hn location/region where the virtual network is created."
  type        = string
}
variable "region_short" {
  description = "Short notation for the region"
  type        = string
}
variable "environment" {
  description = "Name of the environment"
  type        = string
}
variable "address_space" {
  description = "The address spaces applied to the virtual network"
  type        = list(string)
}

variable "nat_config" {
  description = "A nat configuration variable"
  type = object({
    prefix_length = number
    sku           = string
  })
}

variable "subnets" {
  description = "value"
  type = map(object({
    address_prefix                  = optional(string)
    name                            = string
    service_endpoints               = optional(set(string))
    default_outbound_access_enabled = optional(bool, false)
    }
  ))
}

variable "vm_config" {
  description = "VM config variable"
  type = object({
    zone                       = string
    encryption_at_host_enabled = bool
    sku_size                   = string
    os_type                    = string
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    os_disk = object({
      caching              = string
      storage_account_type = string
    })
  })
}

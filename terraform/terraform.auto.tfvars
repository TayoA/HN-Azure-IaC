location      = "UK South"
region_short  = "uks"
environment   = "dev"
address_space = ["10.0.0.0/16"] # CIDR notation for the virtual network
nat_config = {
  prefix_length = 31 # 31 is the smallest prefix length for a public IP prefix
  sku           = "Standard"
}
subnets = {
  "private" = {
    name                            = "private"
    address_prefix                  = "10.0.0.0/24"
    default_outbound_access_enabled = false # private subnet does not need outbound access
  }
  "public" = {
    name                            = "public"
    address_prefix                  = "10.0.1.0/24"
    default_outbound_access_enabled = true
  }
  "management" = {
    name                            = "management" # for creating private endpoint for storage account
    address_prefix                  = "10.0.2.0/24"
    default_outbound_access_enabled = true
  }
}
vm_config = {
  encryption_at_host_enabled = true
  os_type                    = "Linux"
  sku_size                   = "Standard_B1s"
  zone                       = "1" 
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference = {
    publisher = "canonical" 
    offer     = "ubuntu-24_04-lts" 
    sku       = "server" 
    version   = "latest"
  }
}

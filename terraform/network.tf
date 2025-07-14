resource "azurerm_resource_group" "vnet" {
  name     = "rg-${local.identifier}-vnet"
  location = var.location
  tags = merge(local.tags, {
    component = "network"
  })
}

# Create a public IP prefix for NAT Gateway for outbound connectivity, this is creating the public IP prefix that will be used by the NAT Gateway
resource "azurerm_public_ip_prefix" "nat" {
  name                = "pip-${local.identifier}-01"
  location            = azurerm_resource_group.vnet.location
  resource_group_name = azurerm_resource_group.vnet.name
  prefix_length       = var.nat_config.prefix_length
  sku                 = var.nat_config.sku
  tags = merge(local.tags, {
    component = "network"
  })
}

resource "azurerm_nat_gateway" "nat" {
  name                = "nat-${local.identifier}-01"
  location            = azurerm_resource_group.vnet.location
  resource_group_name = azurerm_resource_group.vnet.name
  tags = merge(local.tags, {
    component = "network"
  })
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "nat" {
  nat_gateway_id      = azurerm_nat_gateway.nat.id
  public_ip_prefix_id = azurerm_public_ip_prefix.nat.id
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.9.2"

  address_space       = var.address_space
  location            = azurerm_resource_group.vnet.location
  name                = "vnet-${local.identifier}-01"
  resource_group_name = azurerm_resource_group.vnet.name
  enable_telemetry    = false
  tags = merge(local.tags, {
    component = "network"
  })
}

module "subnets" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"
  version = "0.9.2"

  for_each = var.subnets
  name     = each.value.name
  virtual_network = {
    resource_id = module.vnet.resource_id
  }
  address_prefix                  = each.value.address_prefix
  default_outbound_access_enabled = each.value.default_outbound_access_enabled
  nat_gateway                     = each.value.default_outbound_access_enabled ? null : { id = azurerm_nat_gateway.nat.id } # only private subnet uses NAT Gateway for outbound connectivity, if false, we attach NAT Gateway to the subnet
  service_endpoints               = each.value.service_endpoints
}

module "files_private_dns_zone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.3.5"

  domain_name         = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.vnet.name
  enable_telemetry    = false
  tags = merge(local.tags, {
    component = "network"
  })
  virtual_network_links = {
    "vnet-${local.identifier}-01" = {
      vnetlinkname     = "vnet-${local.identifier}-01-link"
      autoregistration = false
      vnetid           = module.vnet.resource_id
      tags = merge(local.tags, {
        component = "network"
      })
    }
  }
}

module "kv_private_dns_zone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.3.5"

  domain_name         = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.vnet.name
  enable_telemetry    = false
  tags = merge(local.tags, {
    component = "network"
  })
  virtual_network_links = {
    "vnet-${local.identifier}-01" = {
      vnetlinkname     = "vnet-${local.identifier}-01-link"
      autoregistration = false
      vnetid           = module.vnet.resource_id
      tags = merge(local.tags, {
        component = "network"
      })
    }
  }
}

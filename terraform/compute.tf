resource "azurerm_resource_group" "compute" {
  name     = "rg-${local.identifier}-compute"
  location = var.location
  tags = merge(local.tags, {
    component = "network"
  })
}

# creates public key and private key - ssh key pair
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# uploading the private key to the key vault
resource "azurerm_key_vault_secret" "ssh_key" {
  key_vault_id = module.key_vault.resource_id
  name         = "ssh-key"
  value        = tls_private_key.this.private_key_openssh
  depends_on   = [time_sleep.wait_for_kv]
}


module "jump_box_vm_nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.4.0"

  resource_group_name = azurerm_resource_group.compute.name
  location            = azurerm_resource_group.compute.location
  name                = "vm-${local.identifier}-jump-box-nsg"
  enable_telemetry    = false
  security_rules = {
    "allow-ssh" = {
      name                       = "allow-ssh"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_ranges    = ["22"]
      direction                  = "Inbound"
      priority                   = 200
      protocol                   = "Tcp"
      source_address_prefixes    = toset(local.ip_ranges)
      source_port_range          = "*"
    }
  }
}

module "jump_box_vm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.19.3"

  resource_group_name = azurerm_resource_group.compute.name
  location            = azurerm_resource_group.compute.location
  name                = "vm-${local.identifier}-jump-box"
  managed_identities = {    # prerequisite for using Azure AD login
    system_assigned = true
  }
  network_interfaces = {
    network_interface_1 = {
      name = "vm-${local.identifier}-jump-box-nic"
      network_security_groups = {
        nsg1 = {
          network_security_group_resource_id = module.jump_box_vm_nsg.resource_id
        }
      }
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "vm-${local.identifier}-jump-box-nic-ipconfig1"
          private_ip_subnet_resource_id = module.subnets["public"].resource_id
          create_public_ip_address      = true  
          public_ip_address_name        = "vm-${local.identifier}-jump-box-pip"
        }
      }
      is_primary          = true
      resource_group_name = azurerm_resource_group.compute.name
    }
  }
  zone = "1"
  account_credentials = {
    admin_credentials = {
      username                           = "azureuser"
      ssh_keys                           = [tls_private_key.this.public_key_openssh]
      generate_admin_password_or_ssh_key = false
    }
  }
  enable_telemetry           = false
  encryption_at_host_enabled = var.vm_config.encryption_at_host_enabled  # enabes encryption for the underlying host
  os_disk = {
    caching              = var.vm_config.os_disk.caching # caching improves performance by storing frequently accessed data in memory
    storage_account_type = var.vm_config.os_disk.storage_account_type # performace and cost efficiency you want for the OS disk
  }
  os_type  = var.vm_config.os_type
  sku_size = var.vm_config.sku_size
  source_image_reference = {
    publisher = var.vm_config.source_image_reference.publisher
    offer     = var.vm_config.source_image_reference.offer
    sku       = var.vm_config.source_image_reference.sku
    version   = var.vm_config.source_image_reference.version
  }
  tags = merge(local.tags, {
    component = "compute"
  })
  extensions = { # for azure ad ssh login
    azuread-ssh = {
      name                       = "AADLogin"
      publisher                  = "Microsoft.Azure.ActiveDirectory"
      type                       = "AADSSHLoginForLinux"
      type_handler_version       = "1.0"
      auto_upgrade_minor_version = true
  } }
}

#######

module "private_nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.4.0"

  resource_group_name = azurerm_resource_group.compute.name
  location            = azurerm_resource_group.compute.location
  name                = "vm-${local.identifier}-private-nsg"
  enable_telemetry    = false
  security_rules = {
    "allow-ssh" = {
      name                       = "allow-ssh"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_ranges    = ["22"]
      direction                  = "Inbound"
      priority                   = 200
      protocol                   = "Tcp"
      source_address_prefix      = module.jump_box_vm.network_interfaces["network_interface_1"].ip_configuration[0].private_ip_address
      source_port_range          = "*"
    }
  }
}

module "private_vm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.19.3"

  count               = 2
  resource_group_name = azurerm_resource_group.compute.name
  location            = azurerm_resource_group.compute.location
  name                = "vm-${local.identifier}-private-${count.index + 1}"
  managed_identities = {
    system_assigned = true
  }
  network_interfaces = {
    network_interface_1 = {
      name = "vm-${local.identifier}-private-${count.index + 1}-nic"
      network_security_groups = {
        nsg1 = {
          network_security_group_resource_id = module.private_nsg.resource_id
        }
      }
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "vm-${local.identifier}-private-${count.index + 1}-nic-ipconfig1"
          private_ip_subnet_resource_id = module.subnets["private"].resource_id
        }
      }
      is_primary          = true
      resource_group_name = azurerm_resource_group.compute.name
    }
  }
  zone = "1"
  user_data = base64encode(templatefile("./files/cloud-init.tmpl", {
    storage_account_name = module.storage_account.name
    share_name           = "share-1"
    storage_account_key  = module.storage_account.resource.primary_access_key
    file_share_url       = "${module.storage_account.name}.file.core.windows.net"
  }))
  account_credentials = {
    admin_credentials = {
      username                           = "azureuser"
      ssh_keys                           = [tls_private_key.this.public_key_openssh]
      generate_admin_password_or_ssh_key = false
    }
  }
  enable_telemetry           = false
  encryption_at_host_enabled = var.vm_config.encryption_at_host_enabled
  os_disk = {
    caching              = var.vm_config.os_disk.caching
    storage_account_type = var.vm_config.os_disk.storage_account_type
  }
  os_type  = var.vm_config.os_type
  sku_size = var.vm_config.sku_size
  source_image_reference = {
    publisher = var.vm_config.source_image_reference.publisher
    offer     = var.vm_config.source_image_reference.offer
    sku       = var.vm_config.source_image_reference.sku
    version   = var.vm_config.source_image_reference.version
  }
  tags = merge(local.tags, {
    component = "compute"
  })
  extensions = {
    azuread-ssh = {
      name                       = "AADLogin"
      publisher                  = "Microsoft.Azure.ActiveDirectory"
      type                       = "AADSSHLoginForLinux"
      type_handler_version       = "1.0"
      auto_upgrade_minor_version = true
    }
  }
  depends_on = [module.storage_account]
}

resource "azurerm_role_assignment" "reader" {
  role_definition_name = "Reader" # gives sudo access to the users of ssh_admin group on all the VMs under below scope
  scope                = azurerm_resource_group.compute.id
  principal_id         = azuread_group.ssh_admin.object_id
}

resource "azurerm_role_assignment" "ssh_admin" {
  role_definition_name = "Virtual Machine Administrator Login" # gives sudo access to the users of ssh_admin group on all the VMs under below scope
  scope                = azurerm_resource_group.compute.id
  principal_id         = azuread_group.ssh_admin.object_id
}

resource "azurerm_resource_group" "storage" {
  name     = "rg-${local.identifier}-sa"
  location = var.location
  tags = merge(local.tags, {
    component = "storage"
  })
}

# Creates storage account, file shares, private endpoint and management policies for the storage account
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.3"

  account_kind                      = "StorageV2" 
  account_replication_type          = "GRS"
  account_tier                      = "Standard" 
  name                              = replace("sa${local.identifier}stg", "-", "")
  location                          = azurerm_resource_group.storage.location
  resource_group_name               = azurerm_resource_group.storage.name
  enable_telemetry                  = false
  min_tls_version                   = "TLS1_2" 
  https_traffic_only_enabled        = true 
  infrastructure_encryption_enabled = true 
  public_network_access_enabled     = true 
  shared_access_key_enabled         = true 
  blob_properties = {
    versioning_enabled       = true 
    last_access_time_enabled = true
  }
  network_rules = {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    ip_rules                   = toset(local.ip_ranges)
    virtual_network_subnet_ids = []
  }
  shares = {
    share1 = {
      name        = "share-1" 
      quota       = 10        
      access_tier = "Hot"    
    }
  }
  storage_management_policy_rule = {
    "move-to-archive" = {
      enabled = true
      name    = "move-to-archive"
      actions = {
        base_blob = {
          tier_to_archive_after_days_since_modification_greater_than = 7
        }
      }
      filters = {
        blob_types = ["blockBlob"]
      }
    },
    "delete-after-365d" = {
      enabled = true
      name    = "delete-after-365d"
      actions = {
        base_blob = {
          delete_after_days_since_last_access_time_greater_than = 365
        }
      }
      filters = {
        blob_types = ["blockBlob"]
      }
    }
  }
  private_endpoints = {
    "pe-1" = {
      name                          = "pe-${module.storage_account.name}"
      subnet_resource_id            = module.subnets["management"].resource_id
      subresource_name              = "file"
      private_dns_zone_resource_ids = [module.files_private_dns_zone.resource_id]
  
      private_service_connection_name = "psc-${module.storage_account.name}"
      network_interface_name          = "nic-${module.storage_account.name}"
      tags = merge(local.tags, {
        component = "storage"
      })
    }
  }
  private_endpoints_manage_dns_zone_group = true
}

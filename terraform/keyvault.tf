
# Keyvault configuration for Azure using Terraform to store private keys securely which is mandatory for creating the vms
resource "random_string" "random" {
  length  = 4
  special = false
  numeric = false
  upper   = false
}

# Creates key vault and private endpoint
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  name                          = "kv-${local.identifier}-${random_string.random.result}"
  resource_group_name           = azurerm_resource_group.compute.name
  location                      = azurerm_resource_group.compute.location
  enable_telemetry              = false
  sku_name                      = "standard"
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  public_network_access_enabled = true # true for now as i'm runnning on laptop and there's no private connectivity
  network_acls = {
    bypass   = "AzureServices"
    ip_rules = toset(local.ip_ranges)
  }
  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = [module.kv_private_dns_zone.resource_id]
      subnet_resource_id            = module.subnets["management"].resource_id
    }
  }
}

resource "azurerm_role_assignment" "kv_admin" {
  principal_id         = azuread_group.ssh_admin.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = module.key_vault.resource_id
}

resource "time_sleep" "wait_for_kv" {
  depends_on      = [azurerm_role_assignment.kv_admin]
  create_duration = "1m"
}

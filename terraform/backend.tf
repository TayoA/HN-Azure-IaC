terraform {
  backend "azurerm" {
    resource_group_name  = "rg-hn-backend"
    storage_account_name = "hnbackendstorage"
    container_name       = "hntfstate"
    key                  = "hninfra.tfstate"
    use_azuread_auth     = true
  }
}

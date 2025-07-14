terraform {
  required_version = ">=1.12"   #https://releases.hashicorp.com/terraform/
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"  
      version = ">=4.0.0, < 5.0.0"  #https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
    }
  }
}

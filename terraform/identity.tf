resource "azuread_user" "example" {
  user_principal_name = "test-user@tayoayenuroyahoo.onmicrosoft.com"
  display_name        = "Test User"
  mail_nickname       = "tuser"
  password            = "SecretP@ssw0rd" # replace with random_password, a change can be forced by changing the password
  account_enabled = true
}

resource "azuread_group" "ssh_admin" {
  display_name     = "ssh-admin"
  security_enabled = true 
  owners = [
    azuread_user.example.object_id,
  
  ]
  members = [
    azuread_user.example.object_id,              
    data.azurerm_client_config.current.object_id, 
    "afb50d4c-76cd-4bd1-a292-62401bf778d6" 
  ]
}

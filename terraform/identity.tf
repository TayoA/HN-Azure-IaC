resource "azuread_user" "example" {
  user_principal_name = "test-user@tayoayenuroyahoo.onmicrosoft.com"
  display_name        = "Test User"
  mail_nickname       = "tuser"
  password            = "SecretP@ssw0rd" # replace with random_password, a change can be forced by changing the password
  account_enabled = true
}

# member of the ssh-admin group wil be able to ssh to the VM with admin privileges
resource "azuread_group" "ssh_admin" {
  display_name     = "ssh-admin"
  security_enabled = true  # this must be true for role assignments
  owners = [
    azuread_user.example.object_id, # adding the user in the resource above to the group
    #data.azurerm_client_config.current.object_id # adding the current user, the users will
  ]
  members = [
    azuread_user.example.object_id,              # adding the user above 
    data.azurerm_client_config.current.object_id, # adding the current user, the users will be able to ssh to the vm
    "afb50d4c-76cd-4bd1-a292-62401bf778d6" # adding the service principal to the group, this is required for the service principal to be able to ssh to the VM
  ]
}

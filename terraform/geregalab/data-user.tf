data "azuread_user" "owner" {
  user_principal_name = "geregam_outlook.com#EXT#@geregamoutlook.onmicrosoft.com"
}

data "azurerm_client_config" "current" {}

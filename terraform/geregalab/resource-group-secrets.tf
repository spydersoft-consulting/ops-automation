resource "azurerm_resource_group" "secrets" {
  name     = "secrets-rg"
  location = "eastus"
}

resource "azurerm_resource_group" "todelete" {
  name     = "todelete-rg"
  location = "eastus"
}
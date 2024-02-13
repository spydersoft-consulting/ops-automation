resource "azurerm_key_vault" "geregalab" {
  name                        = "geregalab"
  location                    = azurerm_resource_group.secrets.location
  resource_group_name         = azurerm_resource_group.secrets.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
}
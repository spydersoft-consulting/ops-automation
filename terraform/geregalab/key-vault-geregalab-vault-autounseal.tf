# Import the service principal from azuread terraform
data "azuread_service_principal" "vault_autounseal" {
  client_id = var.vault_autounseal_client_id
}

# Grant the Vault auto-unseal service principal access to the key
resource "azurerm_key_vault_access_policy" "vault_autounseal" {
  key_vault_id = azurerm_key_vault.geregalab.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_service_principal.vault_autounseal.object_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey",
  ]
}

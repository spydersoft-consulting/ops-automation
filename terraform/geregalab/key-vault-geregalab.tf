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

# Key for Vault auto-unseal
resource "azurerm_key_vault_key" "vault_unseal" {
  name         = "vault-auto-unseal"
  key_vault_id = azurerm_key_vault.geregalab.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  tags = {
    purpose = "vault-auto-unseal"
  }
}

data "azuread_service_principal" "terraform_lab" {
  client_id = var.terraform_gerega_lab_sp_client_id
}

# Grant the Vault auto-unseal service principal access to the key
resource "azurerm_key_vault_access_policy" "geregalab_terrarom_sp" {
  key_vault_id = azurerm_key_vault.geregalab.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_service_principal.terraform_lab.object_id

  certificate_permissions = [
    "Backup",
    "Create",
    "Delete",
    "DeleteIssuers",
    "Get",
    "GetIssuers",
    "Import",
    "List",
    "ListIssuers",
    "ManageContacts",
    "ManageIssuers",
    "Purge",
    "Recover",
    "Restore",
    "SetIssuers",
    "Update"
  ]

  key_permissions = [
    "Backup",
    "Create",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Get",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
    "Release",
    "Rotate",
    "GetRotationPolicy",
    "SetRotationPolicy"
  ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set"
  ]

  storage_permissions = [
    "Backup",
    "Delete",
    "DeleteSAS",
    "Get",
    "GetSAS",
    "List",
    "ListSAS",
    "Purge",
    "Recover",
    "RegenerateKey",
    "Restore",
    "Set",
    "SetSAS",
    "Update"
  ]
}

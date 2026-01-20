resource "azuread_application" "vault_autounseal" {
  display_name = "Vault Auto-Unseal (K8s)"
  description  = "Service principal for Vault auto-unseal using Azure Key Vault"
  owners       = [data.azuread_user.owner.object_id]

  tags = ["vault", "auto-unseal", "kubernetes"]
}

resource "azuread_service_principal" "vault_autounseal" {
  client_id                    = azuread_application.vault_autounseal.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_user.owner.object_id]
  tags                         = ["WindowsAzureActiveDirectoryIntegratedApp"]
}

resource "time_rotating" "vault_autounseal" {
  rotation_days = 365 # Longer rotation for auto-unseal
}

resource "azuread_service_principal_password" "vault_autounseal" {
  service_principal_id = azuread_service_principal.vault_autounseal.id
  rotate_when_changed = {
    rotation = time_rotating.vault_autounseal.id
  }
}

# Store credentials in Vault for retrieval by External Secrets Operator
resource "vault_kv_secret_v2" "vault_autounseal" {
  mount               = "secrets-k8"
  name                = "vault/autounseal"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode({
    tenant_id     = var.azure_directory_id
    client_id     = azuread_service_principal.vault_autounseal.client_id
    client_secret = azuread_service_principal_password.vault_autounseal.value
    vault_name    = "geregalab"
    key_name      = "vault-auto-unseal"
  })
}

output "vault_autounseal_client_id" {
  description = "Client ID for Vault auto-unseal service principal"
  value       = azuread_application.vault_autounseal.client_id
}

output "vault_autounseal_object_id" {
  description = "Object ID for Vault auto-unseal service principal"
  value       = azuread_service_principal.vault_autounseal.object_id
}

resource "azuredevops_variable_group" "terraform-hcvault" {
  project_id   = azuredevops_project.ops.id
  name         = "terraform-hcvault"
  description  = "[terraform-managed] HC Vault Credentials"
  allow_access = false

  variable {
    name  = "vault-app-role-id"
    value = data.vault_kv_secret_v2.vault-app-role.data["app_role_id"]
  }

  variable {
    name         = "vault-app-role-secret-id"
    secret_value = data.vault_kv_secret_v2.vault-app-role.data["secret_id"]
    is_secret    = true
  }

}
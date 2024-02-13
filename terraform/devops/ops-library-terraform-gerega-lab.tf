resource "azuredevops_variable_group" "terraform-gerega-lab" {
  project_id   = azuredevops_project.ops.id
  name         = "terraform-gerega-lab"
  description  = "[terraform-managed] azuread Service Principal for Terraform"
  allow_access = true

  variable {
    name  = "ARM_CLIENT_ID"
    value = data.vault_kv_secret_v2.geregalab-tf-sp.data["appId"]
  }

  variable {
    name         = "ARM_CLIENT_SECRET"
    secret_value = data.vault_kv_secret_v2.geregalab-tf-sp.data["password"]
    is_secret    = true
  }

  variable {
    name  = "ARM_TENANT_ID"
    value = data.vault_kv_secret_v2.geregalab-tf-sp.data["tenant_id"]
  }
}
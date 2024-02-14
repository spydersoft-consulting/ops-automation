resource "azuredevops_variable_group" "terraform-azuredevops" {
  project_id   = azuredevops_project.ops.id
  name         = "terraform-azure-devops"
  description  = "[terraform-managed] Azure DevOps Credentials"
  allow_access = false

  variable {
    name  = "AZDO_ORG_SERVICE_URL"
    value = data.vault_kv_secret_v2.devops-tf.data["service_url"]
  }

  variable {
    name         = "AZDO_PERSONAL_ACCESS_TOKEN"
    secret_value = data.vault_kv_secret_v2.devops-tf.data["access_token"]
    is_secret    = true
  }

}
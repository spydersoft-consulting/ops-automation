
resource "azuredevops_variable_group" "nuget-spydersoft-develop" {
  project_id   = azuredevops_project.public.id
  name         = "nuget-spydersoft-develop"
  description  = "[terraform-managed] Spydersoft Develop Nuget Credentials"
  allow_access = false

  variable {
    name  = "nuget-feed-url"
    value = data.vault_kv_secret_v2.proget-nuget.data["feedUrl"]
  }

  variable {
    name         = "nuget-feed-api-key"
    secret_value = data.vault_kv_secret_v2.proget-nuget.data["pushApiKey"]
    is_secret    = true
  }
}
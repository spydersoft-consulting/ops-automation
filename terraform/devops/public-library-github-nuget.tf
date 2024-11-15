
resource "azuredevops_variable_group" "nuget-spydersoft-github" {
  project_id   = azuredevops_project.public.id
  name         = "nuget-spydersoft-github"
  description  = "[terraform-managed] Spydersoft Develop Nuget Credentials"
  allow_access = false

  variable {
    name  = "nuget-feed-url"
    value = data.vault_kv_secret_v2.github-nuget.data["feedUrl"]
  }

  variable {
    name         = "nuget-feed-api-key"
    secret_value = data.vault_kv_secret_v2.github-nuget.data["pushApiKey"]
    is_secret    = true
  }
}
resource "azuredevops_serviceendpoint_nuget" "spydersoft-develop" {
  project_id            = azuredevops_project.public.id
  feed_url              = "https://proget.mattgerega.com/nuget/develop/v3/index.json"
  username              = data.vault_kv_secret_v2.proget-nuget.data["username"]
  password              = data.vault_kv_secret_v2.proget-nuget.data["password"]
  service_endpoint_name = "SpydersoftDevelop"
  description           = "Managed by Terraform"
}
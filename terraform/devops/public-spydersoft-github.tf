resource "azuredevops_serviceendpoint_github" "spydersoft-gh" {
  project_id            = azuredevops_project.public.id
  service_endpoint_name = "spydersoft-gh"
  description           = "[terraform-managed] GitHub Service Endpoint for Spydersoft Consulting"

  auth_personal {
    personal_access_token = data.vault_kv_secret_v2.spydersoft-gh-token.data["pat"]
  }
}
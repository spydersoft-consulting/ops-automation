resource "azuredevops_serviceendpoint_github" "ops-github-pat" {
  project_id            = azuredevops_project.ops.id
  service_endpoint_name = "Github"
  description           = "Managed by Terraform"

  auth_personal {
    personal_access_token = data.vault_kv_secret_v2.spydersoft-gh-token.data["pat"]
  }
}

resource "azuredevops_serviceendpoint_github" "spydersoft-consulting" {
  project_id            = azuredevops_project.ops.id
  service_endpoint_name = "spydersoft-consulting"
  description           = ""
}
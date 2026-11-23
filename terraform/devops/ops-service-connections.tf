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

resource "azuredevops_serviceendpoint_github" "ops-spyder007-app-auth" {
  project_id            = azuredevops_project.ops.id
  service_endpoint_name = "spyder007"
  description           = ""
}

import {
  to = azuredevops_serviceendpoint_github.ops-spyder007-app-auth
  id = "97a7b4ed-e5c1-4999-b697-36114643d28c/8491a4b2-e51d-4f50-b30d-d450ded4092d"
}

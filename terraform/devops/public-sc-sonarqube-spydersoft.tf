resource "azuredevops_serviceendpoint_sonarcloud" "sonarcloud-spydersoft" {
  project_id            = azuredevops_project.public.id
  service_endpoint_name = "sonarcloud-spydersoft"
  token                 = data.vault_kv_secret_v2.sonarqube-ado-public-projects.data["token"]
  description           = "Managed by Terraform"
}
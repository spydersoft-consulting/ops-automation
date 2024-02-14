resource "azuredevops_serviceendpoint_github" "spydersoft-consulting-app-auth" {
  project_id            = azuredevops_project.public.id
  service_endpoint_name = "spydersoft-consulting"
  description = ""
}
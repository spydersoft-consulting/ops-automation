resource "azuredevops_serviceendpoint_github" "spyder007-app-auth" {
  project_id            = azuredevops_project.public.id
  service_endpoint_name = "spyder007"
}
resource "azuredevops_serviceendpoint_github" "spydersoft-consulting" {
  project_id            = azuredevops_project.ops.id
  service_endpoint_name = "spydersoft-consulting"
}
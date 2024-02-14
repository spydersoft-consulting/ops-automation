resource "azuredevops_serviceendpoint_dockerregistry" "public-proget" {
  project_id            = azuredevops_project.public.id
  docker_registry       = "https://proget.mattgerega.com"
  docker_username       = data.vault_kv_secret_v2.proget-docker.data["username"]
  docker_password       = data.vault_kv_secret_v2.proget-docker.data["password"]
  service_endpoint_name = "proget_docker"
  description           = "Managed by Terraform"
  registry_type         = "Others"
}
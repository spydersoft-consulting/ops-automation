resource "azuredevops_serviceendpoint_github" "spydersoft-gh" {
  project_id            = azuredevops_project.public.id
  service_endpoint_name = "spydersoft-gh"
  description           = "[terraform-managed] GitHub Service Endpoint for Spydersoft Consulting"

  auth_personal {
    personal_access_token = data.vault_kv_secret_v2.spydersoft-gh-token.data["pat"]
  }
}

resource "azuredevops_serviceendpoint_github" "spydersoft-consulting-app-auth" {
  project_id            = azuredevops_project.public.id
  service_endpoint_name = "spydersoft-consulting"
  description           = ""
}

resource "azuredevops_serviceendpoint_github" "spyder007-app-auth" {
  project_id            = azuredevops_project.public.id
  service_endpoint_name = "spyder007"
  description           = ""
}

resource "azuredevops_serviceendpoint_sonarcloud" "sonarcloud-spydersoft" {
  project_id            = azuredevops_project.public.id
  service_endpoint_name = "sonarcloud-spydersoft"
  token                 = data.vault_kv_secret_v2.sonarqube-ado-public-projects.data["token"]
  description           = "Managed by Terraform"
}

resource "azuredevops_serviceendpoint_nuget" "spydersoft-develop" {
  project_id            = azuredevops_project.public.id
  feed_url              = "https://proget.mattgerega.com/nuget/develop/v3/index.json"
  username              = data.vault_kv_secret_v2.proget-nuget.data["username"]
  password              = data.vault_kv_secret_v2.proget-nuget.data["password"]
  service_endpoint_name = "SpydersoftDevelop"
  description           = "Managed by Terraform"
}

resource "azuredevops_serviceendpoint_nuget" "spydersoft-github" {
  project_id            = azuredevops_project.public.id
  feed_url              = data.vault_kv_secret_v2.github-nuget.data["feed_url"]
  username              = data.vault_kv_secret_v2.github-nuget.data["username"]
  password              = data.vault_kv_secret_v2.github-nuget.data["token"]
  service_endpoint_name = "SpydersoftGithub"
  description           = "Managed by Terraform"
}

resource "azuredevops_serviceendpoint_dockerregistry" "public-proget" {
  project_id            = azuredevops_project.public.id
  docker_registry       = "https://proget.mattgerega.com"
  docker_username       = data.vault_kv_secret_v2.proget-docker.data["username"]
  docker_password       = data.vault_kv_secret_v2.proget-docker.data["password"]
  service_endpoint_name = "proget_docker"
  description           = "Managed by Terraform"
  registry_type         = "Others"
}

resource "azuredevops_serviceendpoint_dockerregistry" "public-github-spydersoft-docker" {
  project_id            = azuredevops_project.public.id
  docker_registry       = "https://ghcr.io"
  docker_username       = data.vault_kv_secret_v2.github-nuget.data["username"]
  docker_password       = data.vault_kv_secret_v2.github-nuget.data["token"]
  service_endpoint_name = "github-spydersoft-docker"
  description           = "Managed by Terraform"
  registry_type         = "Others"
}
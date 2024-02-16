resource "azuredevops_environment" "test" {
  project_id  = azuredevops_project.public.id
  name        = "test"
  description = "[terraform-managed] Test environment"
}

resource "azuredevops_environment" "stage" {
  project_id  = azuredevops_project.public.id
  name        = "stage"
  description = "[terraform-managed] Staging environment"
}

resource "azuredevops_environment" "production" {
  project_id  = azuredevops_project.public.id
  name        = "production"
  description = "[terraform-managed] Production environment"
}
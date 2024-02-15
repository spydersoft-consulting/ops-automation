resource "azuredevops_variable_group" "ops-git" {
  project_id   = azuredevops_project.ops.id
  name         = "git-identity-variables"
  description  = "[terraform-managed] Git Variables"
  allow_access = false

  variable {
    name  = "git-email "
    value = var.git_email
  }

  variable {
    name  = "git-name"
    value = var.git_name
  }

}
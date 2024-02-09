resource "azuredevops_project" "ops" {
  name               = "ops"
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Basic"
  description        = "Projects for various DevOps pipelines.  Managed by Terraform."
  features = {
    "testplans"    = "disabled"
    "artifacts"    = "disabled"
    "boards"       = "disabled"
    "repositories" = "disabled"
    "pipelines"    = "enabled"
  }
}
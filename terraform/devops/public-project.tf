resource "azuredevops_project" "public" {
  name               = "Public Projects"
  visibility         = "public"
  version_control    = "Git"
  work_item_template = "Basic"
  description        = "Pipelines for public projects.  Managed by Terraform."
  features = {
    "testplans"    = "disabled"
    "artifacts"    = "disabled"
    "boards"       = "disabled"
    "repositories" = "disabled"
    "pipelines"    = "enabled"
  }
}
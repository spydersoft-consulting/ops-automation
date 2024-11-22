resource "azuredevops_variable_group" "terraform-gh-spydersoft" {
  project_id   = azuredevops_project.ops.id
  name         = "terraform-gh-spydersoft"
  description  = "[terraform-managed] Github Credentials for Terraform"
  allow_access = false

  variable {
    name  = "GITHUB_TOKEN"
    value = data.vault_kv_secret_v2.github-terraform.data["token"]
  }
}
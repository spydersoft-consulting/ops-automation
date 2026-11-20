resource "azuredevops_build_definition" "ops-docs" {
  project_id = azuredevops_project.ops.id
  name       = "Ops Docs - Publish to Confluence"
  path       = "\\Docs"

  ci_trigger {
    use_yaml = true
  }

  repository {
    branch_name           = "refs/heads/main"
    service_connection_id = azuredevops_serviceendpoint_github.ops-spyder007-app-auth.id # Github App Connection
    repo_type             = "GitHub"
    repo_id               = "spyder007/ops-docs"
    yml_path              = "azure-pipelines.yml"
  }
}

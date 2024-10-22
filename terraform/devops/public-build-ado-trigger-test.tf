resource "azuredevops_build_definition" "ado-trigger-test" {
  project_id = azuredevops_project.public.id
  name       = "ado-trigger-test"
  path       = "\\"

  ci_trigger {
    use_yaml = true
  }

  pull_request_trigger {
    initial_branch = "main"
    use_yaml       = true
    forks {
      enabled       = true
      share_secrets = false
    }
  }

  repository {
    branch_name           = "refs/heads/main"
    service_connection_id = azuredevops_serviceendpoint_github.spyder007-app-auth.id # Github App Connection
    repo_type             = "GitHub"
    repo_id               = "spyder007/ado-trigger-test"
    yml_path              = "build.yml"
  }
}
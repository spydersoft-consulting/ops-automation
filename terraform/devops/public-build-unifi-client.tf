resource "azuredevops_build_definition" "unifi-client" {
  project_id = azuredevops_project.public.id
  name       = "Unifi Client Build"
  path       = "\\Home Automation"

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
    repo_id               = "spyder007/unifi-client"
    yml_path              = ".devops/ci-pipeline.yaml"
  }
}
resource "azuredevops_build_definition" "pitstop-helm-deploy" {
  project_id = azuredevops_project.public.id
  name       = "pitstop-helm-deploy"
  path       = "\\Pit Stop"

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
    service_connection_id = azuredevops_serviceendpoint_github.spydersoft-consulting-app-auth.id # Github App Connection
    repo_type             = "GitHub"
    repo_id               = "spydersoft-consulting/pitstop-helm-config"
    yml_path              = ".devops/pipeline-main.yml"
  }
}

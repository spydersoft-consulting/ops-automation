resource "azuredevops_build_definition" "swing-trade-helm-deploy" {
  project_id = azuredevops_project.public.id
  name       = "swing-trade-helm-deploy"
  path       = "\\Swing Trade"

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
    repo_id               = "spydersoft-consulting/swing-trade-helm-config"
    yml_path              = ".devops/pipeline-deploy.yml"
  }
}

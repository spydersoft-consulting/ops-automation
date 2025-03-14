resource "azuredevops_build_definition" "unifi-helm-deploy" {
  project_id = azuredevops_project.public.id
  name       = "unifi-helm-deploy"
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
    repo_id               = "spyder007/ha-helm-config"
    yml_path              = ".devops/pipeline-main.yml"
  }
}
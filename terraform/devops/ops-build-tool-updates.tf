resource "azuredevops_build_definition" "toolupdates" {
  project_id = azuredevops_project.ops.id
  name       = "Cluster Tool Updates"
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
    service_connection_id = azuredevops_serviceendpoint_github.spydersoft-consulting.id
    repo_type             = "GitHub"
    repo_id               = "spydersoft-consulting/ops-automation"
    yml_path              = ".devops/pipeline-tool-updates.yaml"
  }
}
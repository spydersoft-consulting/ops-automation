resource "azuredevops_build_definition" "tf-geregalab" {
  project_id = azuredevops_project.ops.id
  name       = "terraform-geregalab"
  path       = "\\Terraform"

  ci_trigger {
    use_yaml = true
  }

  pull_request_trigger {
    initial_branch = "main"
    use_yaml = true
    forks {
        enabled = true
        share_secrets = false
    }
  }

  repository {
    branch_name = "refs/heads/main"
    service_connection_id = azuredevops_serviceendpoint_github.spydersoft-consulting.id
    repo_type = "GitHub"
    repo_id = "spydersoft-consulting/ops-automation"
    yml_path = ".devops/pipeline-tf-geregalab.yaml"
  }
}
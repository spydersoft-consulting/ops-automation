resource "azuredevops_build_definition" "cluster-cycle-nonprod" {
  project_id = azuredevops_project.ops.id
  name       = "Cluster Cycling - Nonprod (V2)"
  path       = "\\Cluster Cycling"

  ci_trigger {
    use_yaml = true
  }

  repository {
    branch_name           = "refs/heads/main"
    service_connection_id = azuredevops_serviceendpoint_github.ops-github-pat.id
    repo_type             = "GitHub"
    repo_id               = "spydersoft-consulting/ops-automation"
    yml_path              = ".devops/pipeline-cycle-nonprod-v2.yaml"
  }
}

resource "azuredevops_build_definition" "cluster-cycle-internal" {
  project_id = azuredevops_project.ops.id
  name       = "Cluster Cycling - Internal (V2)"
  path       = "\\Cluster Cycling"

  ci_trigger {
    use_yaml = true
  }

  repository {
    branch_name           = "refs/heads/main"
    service_connection_id = azuredevops_serviceendpoint_github.ops-github-pat.id
    repo_type             = "GitHub"
    repo_id               = "spydersoft-consulting/ops-automation"
    yml_path              = ".devops/pipeline-cycle-internal-v2.yaml"
  }
}

resource "azuredevops_build_definition" "cluster-cycle-prod" {
  project_id = azuredevops_project.ops.id
  name       = "Cluster Cycling - Production (V2)"
  path       = "\\Cluster Cycling"

  ci_trigger {
    use_yaml = true
  }

  repository {
    branch_name           = "refs/heads/main"
    service_connection_id = azuredevops_serviceendpoint_github.ops-github-pat.id
    repo_type             = "GitHub"
    repo_id               = "spydersoft-consulting/ops-automation"
    yml_path              = ".devops/pipeline-cycle-prod-v2.yaml"
  }
}

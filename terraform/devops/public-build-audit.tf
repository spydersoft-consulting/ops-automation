resource "azuredevops_build_definition" "audit-library" {
  project_id = azuredevops_project.public.id
  name       = "spydersoft-audit-library"
  path       = "\\Audit"

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
    repo_id               = "spydersoft-consulting/audit"
    yml_path              = ".devops/pipeline-main.yml"
  }
}

resource "azuredevops_build_definition" "audit-processor" {
  project_id = azuredevops_project.public.id
  name       = "spydersoft-audit-processor"
  path       = "\\Audit"

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
    repo_id               = "spydersoft-consulting/audit"
    yml_path              = ".devops/pipeline-processor.yml"
  }
}

resource "azuredevops_build_definition" "audit-api" {
  project_id = azuredevops_project.public.id
  name       = "spydersoft-audit-api"
  path       = "\\Audit"

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
    repo_id               = "spydersoft-consulting/audit"
    yml_path              = ".devops/pipeline-api.yml"
  }
}

# Single SonarCloud scan covering every C# project in the audit repo. Lives in
# its own pipeline so the library / processor / api pipelines can't run
# simultaneous scans against the same SonarCloud project key and overwrite
# each other's analysis. Triggered on PR validation and main pushes only.
resource "azuredevops_build_definition" "audit-sonar" {
  project_id = azuredevops_project.public.id
  name       = "spydersoft-audit-sonar"
  path       = "\\Audit"

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
    repo_id               = "spydersoft-consulting/audit"
    yml_path              = ".devops/pipeline-sonar.yml"
  }
}

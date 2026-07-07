# pitstop-helm-config's test-environment trigger used to be a branch
# condition inside pipeline-main.yml (main vs feature/*), handled by a
# single build definition (public-build-pitstop-helm-deploy.tf). It's now a
# separate path-triggered pipeline file (pipeline-test.yml), which needs its
# own build definition -- see the migration notes in pitstop-helm-config's
# .devops/pipeline-test.yml and .devops/pipeline-main.yml for why.
resource "azuredevops_build_definition" "pitstop-helm-deploy-test" {
  project_id = azuredevops_project.public.id
  name       = "pitstop-helm-deploy-test"
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
    yml_path              = ".devops/pipeline-test.yml"
  }
}

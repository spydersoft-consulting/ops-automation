# One build definition for the whole repo: pipeline-ci.yml builds the
# solution, runs the unit, API and web integration suites, publishes the API
# and web images, and publishes the swing-trade chart from a single build
# number (see swing-trade/.devops/pipeline-ci.yml). Mirrors public-build-pitstop.tf.
resource "azuredevops_build_definition" "swing-trade" {
  project_id = azuredevops_project.public.id
  name       = "swing-trade"
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
    repo_id               = "spydersoft-consulting/swing-trade"
    yml_path              = ".devops/pipeline-ci.yml"
  }
}

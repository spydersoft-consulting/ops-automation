# Transitional name (pitstop-monorepo) to avoid colliding with the existing
# pitstop-api / pitstop-web build definitions, which still point at the old
# repos and are left running until those repos are archived. Rename to
# "pitstop" once the old build definitions and repos are removed.
#
# One build definition for the whole repo: pipeline-ci.yml builds both
# solutions, publishes both images, and publishes the combined chart from a
# single build number (see pitstop/.devops/pipeline-ci.yml).
resource "azuredevops_build_definition" "pitstop-monorepo" {
  project_id = azuredevops_project.public.id
  name       = "pitstop-monorepo"
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
    repo_id               = "spydersoft-consulting/pitstop"
    yml_path              = ".devops/pipeline-ci.yml"
  }
}

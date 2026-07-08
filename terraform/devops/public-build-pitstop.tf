# One build definition for the whole repo: pipeline-ci.yml builds both
# solutions, publishes both images, and publishes the combined chart from a
# single build number (see pitstop/.devops/pipeline-ci.yml).
#
# The old pitstop-api / pitstop-web build definitions have been removed
# (public-build-pitstop-api.tf, public-build-pitstop-web.tf) now that
# pitstop-api/pitstop-web are archived -- see repo-pitstop-api.tf /
# repo-pitstop-web.tf in the gh-spydersoft project.
resource "azuredevops_build_definition" "pitstop" {
  project_id = azuredevops_project.public.id
  name       = "pitstop"
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

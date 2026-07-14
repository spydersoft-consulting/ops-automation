# One build definition for the whole repo: pipeline-ci.yml now builds both
# the API and the web UI (merged in from unifi-client) and publishes one
# combined chart from a single build number (see
# unifi-ipmanager/.devops/pipeline-ci.yml). The repo/yml_path below already
# pointed at the merged repo before this rename, so only the display name
# changes here -- the resource address (unifi-ipmanager-api) is kept as-is
# to avoid a destroy/recreate of the existing build definition on apply.
#
# The old standalone unifi-client build definition has been removed
# (public-build-unifi-client.tf) now that unifi-client's content lives in
# unifi-ipmanager's frontend/ -- the unifi-client repo itself is untouched
# and still exists on GitHub, just no longer built.
resource "azuredevops_build_definition" "unifi-ipmanager-api" {
  project_id = azuredevops_project.public.id
  name       = "unifi-ipmanager"
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
    repo_id               = "spyder007/unifi-ipmanager"
    yml_path              = ".devops/pipeline-ci.yml"
  }
}
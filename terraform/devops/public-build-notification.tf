# One build definition for the whole repo: pipeline-ci.yml builds the
# solution, publishes both service images (notification-api, notification-hub),
# the combined chart, AND the Spydersoft.Notification.Contracts/Client NuGet
# packages, all from a single build number (see notification/.devops/pipeline-ci.yml).
# Same shape as audit's consolidated build definition.
#
# NOTE: this pipeline consumes the nuget-spydersoft-github variable group
# (allow_access = false in public-library-github-nuget.tf). The first run of
# this pipeline will need a one-time manual "Permit" click in the Azure
# DevOps UI when it requests that variable group -- Terraform has no
# authorization resource for this (see the same note in public-build-audit.tf).
resource "azuredevops_build_definition" "notification" {
  project_id = azuredevops_project.public.id
  name       = "spydersoft-notification"
  path       = "\\Notification"

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
    repo_id               = "spydersoft-consulting/notification"
    yml_path              = ".devops/pipeline-ci.yml"
  }
}

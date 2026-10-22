# One build definition for the whole repo: pipeline-ci.yml builds the
# solution, publishes the email-api image, the chart, AND the
# Spydersoft.Email.Client NuGet package, all from a single build number
# (see email/.devops/pipeline-ci.yml).
#
# NOTE: this pipeline consumes the nuget-spydersoft-github variable group
# (allow_access = false in public-library-github-nuget.tf). The first run of
# this pipeline will need a one-time manual "Permit" click in the Azure
# DevOps UI when it requests that variable group -- Terraform has no
# authorization resource for this (see the same note in public-build-audit.tf).
resource "azuredevops_build_definition" "email" {
  project_id = azuredevops_project.public.id
  name       = "spydersoft-email"
  path       = "\\Email"

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
    repo_id               = "spydersoft-consulting/email"
    yml_path              = ".devops/pipeline-ci.yml"
  }
}

# One build definition for the whole repo: pipeline-ci.yml builds the
# solution, publishes both service images (audit-api, audit-processor), the
# combined chart, AND the Spydersoft.Audit/Spydersoft.Audit.Client NuGet
# packages, all from a single build number (see audit/.devops/pipeline-ci.yml).
# Replaces the old separate audit-library / audit-processor / audit-api /
# audit-sonar build definitions.
#
# NOTE: this pipeline consumes the nuget-spydersoft-github variable group
# (allow_access = false in public-library-github-nuget.tf), which previously
# only had spydersoft-audit-library authorized against it. The first run of
# this consolidated pipeline will need a one-time manual "Permit" click in
# the Azure DevOps UI when it requests that variable group -- Terraform has
# no authorization resource for this (none existed for the old setup either).
resource "azuredevops_build_definition" "audit" {
  project_id = azuredevops_project.public.id
  name       = "spydersoft-audit"
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
    yml_path              = ".devops/pipeline-ci.yml"
  }
}

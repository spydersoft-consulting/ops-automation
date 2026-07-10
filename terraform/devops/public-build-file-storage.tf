# Renamed from "file-storage" / "file-storage-build" (and moved out of the
# "\Identity" ADO folder, a copy-paste leftover) to match the naming
# convention used by the other single-build-definition apps (audit,
# pitstop). moved block preserves the existing build definition's ID/history
# instead of destroying and recreating it.
moved {
  from = azuredevops_build_definition.file-storage
  to   = azuredevops_build_definition.filestore_api
}

resource "azuredevops_build_definition" "filestore_api" {
  project_id = azuredevops_project.public.id
  name       = "filestore-api"
  path       = "\\File Storage"

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
    repo_id               = "spydersoft-consulting/file-storage"
    yml_path              = ".devops/pipeline-ci.yml"
  }
}
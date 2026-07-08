# Manual approval gates on the shared stage/production Environments.
# These environments are used by every app's stage/production deploy
# stage (techradar, platform, pitstop, etc. all bind to the same
# environment: "stage" / "production" via the shared
# stages-generate-commit-manifests template) -- this is a deliberate,
# org-wide gate, not pitstop-specific. See pitstop-helm-config's
# combined deploy pipeline for the release-vs-beta stage-skip logic that
# determines whether a run even reaches these checks.
resource "azuredevops_check_approval" "stage" {
  project_id            = azuredevops_project.public.id
  target_resource_id    = azuredevops_environment.stage.id
  target_resource_type  = "environment"
  requester_can_approve = true
  approvers             = ["7d259c26-98a2-42e0-825a-fa9020ccb00f"] # Matt Gerega
  timeout               = 43200
}

resource "azuredevops_check_approval" "production" {
  project_id            = azuredevops_project.public.id
  target_resource_id    = azuredevops_environment.production.id
  target_resource_type  = "environment"
  requester_can_approve = true
  approvers             = ["7d259c26-98a2-42e0-825a-fa9020ccb00f"] # Matt Gerega
  timeout               = 43200
}

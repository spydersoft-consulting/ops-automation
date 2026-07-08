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

# No matching resource for "production": one already exists there (check id
# 5, created manually 2021-04-15, same approver/timeout as stage's above),
# and azuredevops_check_approval doesn't support `terraform import`/`tofu
# import` at all (SDKv2 provider limitation -- confirmed via a real apply:
# "resource azuredevops_check_approval doesn't support import"). Rather
# than fight the provider, production's approval gate stays unmanaged here,
# same as it always has been. Functionally identical outcome either way --
# the check exists and works, whether or not this file is the thing that
# created it.
# The new combined pitstop monorepo (src/api + src/web + charts/pitstop),
# replacing pitstop-api and pitstop-web. Those two repos' resources
# (pitstop_api / pitstop_web below in repo-pitstop-api.tf / repo-pitstop-web.tf)
# are intentionally left untouched here -- they get archived on GitHub
# manually once the new repo is verified, not torn down by this change.

resource "github_repository" "pitstop" {
  name                        = "pitstop"
  description                 = "PitStop - Fuel consumption tracking system (API + web, monorepo)"
  allow_auto_merge            = false
  allow_merge_commit          = true
  allow_rebase_merge          = true
  allow_squash_merge          = true
  allow_update_branch         = false
  archived                    = false
  auto_init                   = false
  delete_branch_on_merge      = true
  has_discussions             = false
  has_downloads               = true
  has_issues                  = true
  has_projects                = true
  has_wiki                    = true
  is_template                 = false
  topics                      = []
  visibility                  = "public"
  vulnerability_alerts        = false
  web_commit_signoff_required = false

  security_and_analysis {
    secret_scanning {
      status = "disabled"
    }
    secret_scanning_push_protection {
      status = "disabled"
    }
  }
}

resource "github_branch_protection" "pitstop_main" {
  repository_id = github_repository.pitstop.node_id
  pattern       = "main"

  allows_deletions                = false
  allows_force_pushes             = false
  enforce_admins                  = false
  force_push_bypassers            = []
  lock_branch                     = false
  require_conversation_resolution = true
  require_signed_commits          = false
  required_linear_history         = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    dismissal_restrictions          = []
    pull_request_bypassers          = []
    require_code_owner_reviews      = false
    require_last_push_approval      = false
    required_approving_review_count = 1
    restrict_dismissals             = false
  }

  # Status check context name comes from the single ADO build definition in
  # public-build-pitstop-monorepo.tf plus the combined SonarCloud project
  # (spydersoft-consulting_pitstop -- must exist in SonarCloud, see
  # pitstop/.devops/pipeline-ci.yml's header comment) -- verify these
  # literal names against what GitHub actually shows after the first real
  # pipeline run before relying on this to gate merges.
  required_status_checks {
    contexts = ["pitstop-monorepo", "SonarCloud Code Analysis"]
    strict   = false
  }
}

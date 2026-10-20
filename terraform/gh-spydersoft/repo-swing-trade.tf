moved {
  from = github_repository.swing-trade
  to   = github_repository.swing_trade
}

resource "github_repository" "swing_trade" {
  name                        = "swing-trade"
  description                 = "swing-trade - Simple Swing Trading Tool"
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

resource "github_branch_protection" "swing_trade_main" {
  repository_id = github_repository.swing_trade.node_id
  pattern       = "main"

  allows_deletions                = false
  allows_force_pushes             = false
  enforce_admins                  = false
  force_push_bypassers            = []
  lock_branch                     = false
  require_conversation_resolution = true
  require_signed_commits          = false
  required_linear_history         = false

  restrict_pushes {
    blocks_creations = false
    push_allowances  = ["/spyder007"]
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    dismissal_restrictions          = []
    pull_request_bypassers          = []
    require_code_owner_reviews      = false
    require_last_push_approval      = false
    required_approving_review_count = 0
    restrict_dismissals             = false
  }

  # "swing-trade" is the ADO build definition in public-build-swing-trade.tf. SonarCloud
  # reports one check per analysed project and prefixes it with the project name,
  # so the .NET and web UI projects each report their own context.
  required_status_checks {
    contexts = [
      "swing-trade",
      "[Swing Trade] SonarCloud Code Analysis",
      "[Swing Trade Web UI] SonarCloud Code Analysis",
    ]
    strict = false
  }
}

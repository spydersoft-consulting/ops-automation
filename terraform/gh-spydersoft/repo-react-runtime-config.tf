resource "github_repository" "react_runtime_config" {
  name                        = "react-runtime-config"
  description                 = "Provide a typesafe runtime configuration inside a react app"
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
  has_issues                  = false
  has_projects                = true
  has_wiki                    = false
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

resource "github_branch_protection" "react_runtime_config_main" {
  repository_id = github_repository.react_runtime_config.node_id
  pattern       = "main"

  allows_deletions                = false
  allows_force_pushes             = false
  enforce_admins                  = false
  force_push_bypassers            = []
  lock_branch                     = false
  require_conversation_resolution = true
  require_signed_commits          = false
  required_linear_history         = true

  required_pull_request_reviews {
    dismiss_stale_reviews           = false
    dismissal_restrictions          = []
    pull_request_bypassers          = []
    require_code_owner_reviews      = true
    require_last_push_approval      = false
    required_approving_review_count = 1
    restrict_dismissals             = false
  }

  required_status_checks {
    contexts = []
    strict   = true
  }
}

import {
  id = "react-runtime-config:main"
  to = github_branch_protection.react_runtime_config_main
}
    
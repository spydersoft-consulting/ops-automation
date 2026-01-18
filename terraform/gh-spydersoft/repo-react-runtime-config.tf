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
    
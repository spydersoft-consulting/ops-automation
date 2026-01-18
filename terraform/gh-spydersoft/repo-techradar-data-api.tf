resource "github_repository" "techradar_data_api" {
  name                        = "techradar-data-api"
  description                 = "Technology Radar Data API"
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
    
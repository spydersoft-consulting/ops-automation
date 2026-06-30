

resource "github_repository" "pitstop_helm_config" {
  name                        = "pitstop-helm-config"
  description                 = ""
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
  visibility                  = "private"
  vulnerability_alerts        = false
  web_commit_signoff_required = false
}

# No github_branch_protection resource: branch protection on private
# repositories is not available on the org's free GitHub plan.

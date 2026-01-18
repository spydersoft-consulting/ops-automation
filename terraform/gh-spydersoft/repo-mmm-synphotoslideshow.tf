resource "github_repository" "mmm_synphotoslideshow" {
  name                        = "MMM-SynPhotoSlideshow"
  description                 = "MagicMirror Module for Synology Photo Slideshow"
  allow_auto_merge            = false
  allow_merge_commit          = true
  allow_rebase_merge          = false
  allow_squash_merge          = true
  allow_update_branch         = false
  archived                    = false
  auto_init                   = false
  delete_branch_on_merge      = true
  has_discussions             = false
  has_downloads               = true
  has_issues                  = true
  has_projects                = false
  has_wiki                    = false
  is_template                 = false
  topics                      = []
  visibility                  = "public"
  vulnerability_alerts        = true
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


import {
  to = github_repository.mmm_synphotoslideshow
  id = "MMM-SynPhotoSlideshow" # The unique ID of the resource in GitHub
}
    
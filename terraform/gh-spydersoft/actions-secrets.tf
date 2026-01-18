resource "github_actions_organization_secret" "sonar_token" {
  secret_name     = "SONAR_TOKEN"
  visibility      = "selected"
  plaintext_value = data.vault_kv_secret_v2.github-sonar.data["github-actions"]
  selected_repository_ids = [
    github_repository.md_to_conf.repo_id, 
    github_repository.mmm_googletasks.repo_id,
    github_repository.mmm_prometheusalerts.repo_id,
    github_repository.mmm_statuspageio.repo_id,
    github_repository.mmm_synphotoslideshow.repo_id,
    github_repository.pi_monitor.repo_id,
    github_repository.react_runtime_config.repo_id
 ]
}

resource "github_actions_organization_secret" "pypi_api_token" {
  secret_name     = "PYPI_API_TOKEN"
  visibility      = "selected"
  plaintext_value = data.vault_kv_secret_v2.github-pypi.data["api-token"]
  selected_repository_ids = [
    github_repository.md_to_conf.repo_id, 
    github_repository.pi_monitor.repo_id,
 ]
}
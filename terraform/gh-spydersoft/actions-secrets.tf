resource "github_actions_secret" "windows_dns_api_user" {
  repository      = "windows-dns-api"
  secret_name     = "RESOURCE_USER"
  plaintext_value = data.vault_kv_secret_v2.github-terraform.data["user"]
}

resource "github_actions_secret" "windows_dns_api_token" {
  repository      = "windows-dns-api"
  secret_name     = "RESOURCE_TOKEN"
  plaintext_value = data.vault_kv_secret_v2.github-terraform.data["token"]
}

resource "github_actions_secret" "hyperv_info_api_user" {
  repository      = "hyperv-info-api"
  secret_name     = "RESOURCE_USER"
  plaintext_value = data.vault_kv_secret_v2.github-terraform.data["user"]
}

resource "github_actions_secret" "hyperv_info_api_token" {
  repository      = "hyperv-info-api"
  secret_name     = "RESOURCE_TOKEN"
  plaintext_value = data.vault_kv_secret_v2.github-terraform.data["token"]
}
resource "github_actions_secret" "windows_dns_api_user" {
  repository      = "spyder007/windows-dns-api"
  secret_name     = "RESOURCE_USER"
  plaintext_value = data.vault_kv_secret_v2.github-terraform.data["user"]
}
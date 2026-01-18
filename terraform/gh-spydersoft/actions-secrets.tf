# resource "github_actions_secret" "windows_dns_api_user" {
#   repository      = "windows-dns-api"
#   secret_name     = "RESOURCE_USER"
#   plaintext_value = data.vault_kv_secret_v2.github-terraform.data["user"]
# }

# resource "github_actions_secret" "windows_dns_api_token" {
#   repository      = "windows-dns-api"
#   secret_name     = "RESOURCE_TOKEN"
#   plaintext_value = data.vault_kv_secret_v2.github-terraform.data["token"]
# }

# resource "github_actions_secret" "hyperv_info_api_user" {
#   repository      = "hyperv-info-api"
#   secret_name     = "RESOURCE_USER"
#   plaintext_value = data.vault_kv_secret_v2.github-terraform.data["user"]
# }

# resource "github_actions_secret" "hyperv_info_api_token" {
#   repository      = "hyperv-info-api"
#   secret_name     = "RESOURCE_TOKEN"
#   plaintext_value = data.vault_kv_secret_v2.github-terraform.data["token"]
# }

# ### Sonar Token

# resource "github_actions_secret" "sonar_token" {
#   for_each       = toset(var.sonar_token_repositories)
#   repository      = each.key
#   secret_name     = "SONAR_TOKEN"
#   plaintext_value = data.vault_kv_secret_v2.github-sonar.data["github-actions"]
# }

# ### PyPI API Token

# resource "github_actions_secret" "md_to_conf_pypi_api_token" {
#   repository      = "md_to_conf"
#   secret_name     = "PYPI_API_TOKEN"
#   plaintext_value = data.vault_kv_secret_v2.github-pypi.data["api-token"]
# }

# resource "github_actions_secret" "pi_monitor_pypi_api_token" {
#   repository      = "pi-monitor"
#   secret_name     = "PYPI_API_TOKEN"
#   plaintext_value = data.vault_kv_secret_v2.github-pypi.data["api-token"]
# }
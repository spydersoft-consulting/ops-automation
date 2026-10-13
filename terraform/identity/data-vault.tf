# client_credentials client (identity:admin:read + identity:admin:write) that the
# provider uses to call the admin API of this environment. One secret per
# environment, with fields clientId and clientSecret.
data "vault_kv_secret_v2" "provider_credentials" {
  mount = "secrets-infra"
  name  = "identity/${var.environment}/terraform"
}

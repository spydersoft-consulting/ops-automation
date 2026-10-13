# Secrets for the Swing Trade identity clients. Nothing is stored in this
# repository: create these Vault entries first (see the commands below), then
# apply. The BFF's ExternalSecret reads the same "auth" entry.
#
#   vault kv put -mount=secrets-k8 swing-trade/test/auth \
#     authority=https://auth.mattgerega.net \
#     client_id=swingtrade-web \
#     client_secret="$(openssl rand -base64 48)"
#
#   vault kv put -mount=secrets-k8 swing-trade/test/claude-connector \
#     client_secret="$(openssl rand -base64 48)"
#
# Repeat for production (authority https://auth.mattgerega.com). The pipeline's
# Vault AppRole needs read access to secrets-k8/data/swing-trade/*.

data "vault_kv_secret_v2" "swingtrade_web_auth" {
  mount = "secrets-k8"
  name  = "swing-trade/${var.environment}/auth"
}

data "vault_kv_secret_v2" "swingtrade_claude_connector" {
  mount = "secrets-k8"
  name  = "swing-trade/${var.environment}/claude-connector"
}

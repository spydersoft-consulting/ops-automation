# identity-server calls the email service as a machine client (client_credentials,
# email:send). The secret lives in Vault and is never written here; create it
# first, then apply:
#
#   vault kv put -mount=secrets-k8 identity/test/email-client \
#     client_id=identity-server \
#     client_secret="$(openssl rand -base64 48)"
#
# The identity-server deployment's ExternalSecret reads the same entry.

data "vault_kv_secret_v2" "identity_server_email_client" {
  count = local.test_only

  mount = "secrets-k8"
  name  = "identity/${var.environment}/email-client"
}

resource "spydersoftidentity_client" "identity_server" {
  count = local.test_only

  client_id           = data.vault_kv_secret_v2.identity_server_email_client[0].data["client_id"]
  client_name         = "Identity Server"
  allowed_grant_types = ["client_credentials"]
  allowed_scopes      = ["email:send"]
}

resource "spydersoftidentity_client_secret" "identity_server" {
  count = local.test_only

  client      = spydersoftidentity_client.identity_server[0].id
  value       = data.vault_kv_secret_v2.identity_server_email_client[0].data["client_secret"]
  description = "managed by terraform; source: Vault secrets-k8/identity/${var.environment}/email-client"
}

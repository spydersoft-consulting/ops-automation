# Swing Trade (https://github.com/spydersoft-consulting/swing-trade).
# See swing-trade/docs/IDENTITY_SETUP.md for what each object is for.
#
# New objects, not imported: they are managed in every environment
# (local.everywhere), unlike the older test-only imports in the other files.
# Roles (swingtrade.reader/.trader/.admin/.mcp) and their assignment to users
# are ASP.NET Identity data, not managed by this provider: create them and
# assign them to the owner in the identity admin UI.

locals {
  # Host the UI/BFF is served from, per environment (DECISIONS #116).
  swingtrade_domain = var.environment == "production" ? "mattgerega.com" : "mattgerega.net"
  swingtrade_ui     = "https://swingtrade.${local.swingtrade_domain}"
}

# --- Scope and API resource -------------------------------------------------

resource "spydersoftidentity_scope" "swingtrade" {
  count = local.everywhere

  name                       = "swingtrade"
  display_name               = "Swing Trade API"
  show_in_discovery_document = false
}

# Naming the resource "swingtrade" makes the access token carry aud=swingtrade
# when the scope is requested. user_claims puts the role claim into the access
# token, which is where the API reads it.
resource "spydersoftidentity_api_resource" "swingtrade" {
  count = local.everywhere

  name         = "swingtrade"
  display_name = "Swing Trade API"
  scopes       = [spydersoftidentity_scope.swingtrade[0].name]
  user_claims  = ["sub", "role"]
}

# --- Clients ----------------------------------------------------------------

# The web BFF (OidcProxy). Confidential, authorization code. The client id and
# secret live in Vault, the same entry the app's ExternalSecret reads, so the
# identity server and the app can never disagree.
resource "spydersoftidentity_client" "swingtrade_web" {
  count = local.everywhere

  client_id                              = data.vault_kv_secret_v2.swingtrade_web_auth.data["client_id"]
  client_name                            = "Swing Trade Web"
  require_consent                        = false
  require_pkce                           = false # matches pitstop-web (OidcProxy)
  allow_remember_consent                 = false
  back_channel_logout_session_required   = false
  front_channel_logout_session_required  = false
  allow_offline_access                   = true
  always_include_user_claims_in_id_token = true
  sliding_refresh_token_lifetime         = 2592000
  refresh_token_expiration               = 1
  refresh_token_usage                    = 1
  allowed_grant_types                    = ["authorization_code"]
  allowed_scopes                         = ["email", "offline_access", "openid", "profile", spydersoftidentity_scope.swingtrade[0].name]
  redirect_uris = [
    "${local.swingtrade_ui}/.auth/login/callback",
    "${local.swingtrade_ui}/oauth2/callback",
  ]
  post_logout_redirect_uris = [
    "${local.swingtrade_ui}/",
    "${local.swingtrade_ui}/.auth/end-session/callback",
  ]
}

# The Claude custom connector (claude.ai, Desktop, mobile): confidential,
# authorization code + PKCE S256. Anthropic's servers call back to a fixed URL.
# The owner pastes this client id and the Vault secret into the connector's
# Advanced settings.
resource "spydersoftidentity_client" "swingtrade_claude_connector" {
  count = local.everywhere

  client_id             = "swingtrade-claude-connector"
  client_name           = "Claude custom connector (Swing Trade MCP)"
  require_consent       = false
  require_pkce          = true
  allow_plain_text_pkce = false
  require_client_secret = true
  allow_offline_access  = true
  access_token_lifetime = 3600
  allowed_grant_types   = ["authorization_code"]
  allowed_scopes        = ["offline_access", spydersoftidentity_scope.swingtrade[0].name]
  redirect_uris         = ["https://claude.ai/api/mcp/auth_callback"]
}

# Claude Code (CLI): public client, no secret, PKCE S256. The CLI picks a random
# loopback port on every login, so the URIs are registered without a port. That
# only works once the identity server has LoopbackRedirectUriValidator deployed
# (swing-trade/docs/IDENTITY_SETUP.md, "Client 2"); until then every login fails
# with invalid_redirect_uri.
resource "spydersoftidentity_client" "swingtrade_claude_code" {
  count = local.everywhere

  client_id             = "swingtrade-claude-code"
  client_name           = "Claude Code (Swing Trade MCP)"
  require_consent       = false
  require_pkce          = true
  allow_plain_text_pkce = false
  require_client_secret = false
  allow_offline_access  = true
  access_token_lifetime = 3600
  allowed_grant_types   = ["authorization_code"]
  allowed_scopes        = ["offline_access", spydersoftidentity_scope.swingtrade[0].name]
  redirect_uris         = ["http://127.0.0.1", "http://localhost"]
}

# --- Client secrets, read from Vault ---------------------------------------
# The values are never written in this repository. Terraform reads them from
# Vault (swing-trade-vault.tf) and the identity server hashes them. The plain
# value is also kept in the Terraform state (the provider cannot avoid that), so
# the state backend must stay private. Changing the value in Vault and applying
# replaces the secret on the server.

resource "spydersoftidentity_client_secret" "swingtrade_web" {
  count = local.everywhere

  client      = spydersoftidentity_client.swingtrade_web[0].id
  value       = data.vault_kv_secret_v2.swingtrade_web_auth.data["client_secret"]
  description = "managed by terraform; source: Vault secrets-k8/swing-trade/${var.environment}/auth"
}

resource "spydersoftidentity_client_secret" "swingtrade_claude_connector" {
  count = local.everywhere

  client      = spydersoftidentity_client.swingtrade_claude_connector[0].id
  value       = data.vault_kv_secret_v2.swingtrade_claude_connector.data["client_secret"]
  description = "managed by terraform; source: Vault secrets-k8/swing-trade/${var.environment}/claude-connector"
}

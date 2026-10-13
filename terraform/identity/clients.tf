# Imported from the test identity server. Managed in test only for now.
# Client secrets are not managed here (the server never returns them).

resource "spydersoftidentity_client" "client" {
  count = local.test_only

  client_id                = "client"
  client_name              = ""
  require_consent          = false
  include_jwt_id           = true
  refresh_token_expiration = 1
  allowed_grant_types      = ["client_credentials"]
  allowed_scopes           = ["api", "notification:read", "notification:write"]
}

resource "spydersoftidentity_client" "ro_client" {
  count = local.test_only

  client_id                = "ro.client"
  client_name              = ""
  require_consent          = false
  include_jwt_id           = true
  refresh_token_expiration = 1
  allowed_grant_types      = ["password"]
  allowed_scopes           = ["api"]
}

resource "spydersoftidentity_client" "mvc" {
  count = local.test_only

  client_id                 = "mvc"
  client_name               = "MVC Client"
  allow_offline_access      = true
  include_jwt_id            = true
  refresh_token_expiration  = 1
  allowed_grant_types       = ["client_credentials", "hybrid"]
  allowed_scopes            = ["api", "openid", "profile"]
  redirect_uris             = ["http://localhost:5002/signin-oidc"]
  post_logout_redirect_uris = ["http://localhost:5002"]
}

resource "spydersoftidentity_client" "pitstop_dev_client" {
  count = local.test_only

  client_id                             = "pitstop-dev-client"
  client_name                           = "Pitstop Development Client"
  require_consent                       = false
  require_pkce                          = false
  allow_remember_consent                = false
  enable_local_login                    = false
  back_channel_logout_session_required  = false
  front_channel_logout_session_required = false
  refresh_token_expiration              = 1
  refresh_token_usage                   = 1
  allowed_grant_types                   = ["client_credentials"]
  allowed_scopes                        = ["openid", "pitstop:read", "pitstop:write", "profile"]
}

resource "spydersoftidentity_client" "postman_client" {
  count = local.test_only

  client_id                              = "postman.client"
  client_name                            = "Postman"
  require_consent                        = false
  require_pkce                           = false
  allow_offline_access                   = true
  allow_access_tokens_via_browser        = true
  always_send_client_claims              = true
  always_include_user_claims_in_id_token = true
  allowed_grant_types                    = ["authorization_code"]
  allowed_scopes                         = ["address", "audit:read", "email", "filestore:read", "filestore:write", "identity:admin:read", "identity:admin:write", "identity:read", "identity:write", "notification:read", "notification:write", "offline_access", "openid", "phone", "pitstop:read", "pitstop:write", "profile", "roles", "unifi.ipmanager"]
  redirect_uris                          = ["http://localhost:1234", "https://pitstop.mattgerega.net/oauth2/callback"]
}

resource "spydersoftidentity_client" "pitstop_api" {
  count = local.test_only

  client_id           = "pitstop-api"
  client_name         = "PitStop API"
  allowed_grant_types = ["client_credentials"]
  allowed_scopes      = ["filestore:read", "filestore:write", "notification:read", "notification:write"]
}

resource "spydersoftidentity_client" "pitstop_web" {
  count = local.test_only

  client_id                              = "pitstop-web"
  client_name                            = "Pitstop Web Client - Development"
  require_consent                        = false
  require_pkce                           = false
  allow_remember_consent                 = false
  back_channel_logout_session_required   = false
  front_channel_logout_session_required  = false
  allow_offline_access                   = true
  always_include_user_claims_in_id_token = true
  sliding_refresh_token_lifetime         = 2592000
  refresh_token_expiration               = 1
  refresh_token_usage                    = 1
  allowed_grant_types                    = ["authorization_code"]
  allowed_scopes                         = ["email", "notification:read", "notification:write", "openid", "pitstop:read", "pitstop:write", "profile"]
  redirect_uris                          = ["https://localhost:5200/.auth/login/callback", "https://pitstop.mattgerega.net/.auth/login/callback", "https://pitstop.mattgerega.net/oauth2/callback"]
}
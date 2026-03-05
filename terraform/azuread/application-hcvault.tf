resource "azuread_application" "hcvault" {
  display_name            = "Hashicorp Vault"
  group_membership_claims = ["All"]

  optional_claims {
    access_token {
      essential             = false
      name                  = "groups"
      additional_properties = []
    }
    id_token {
      essential             = false
      name                  = "groups"
      additional_properties = []
    }
    saml2_token {
      essential             = false
      name                  = "groups"
      additional_properties = []
    }
  }

  required_resource_access {
    resource_app_id = data.azuread_service_principal.graph.client_id
    resource_access {
      id   = data.azuread_service_principal.graph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }

  web {
    redirect_uris = [
      "https://hcvault.mattgerega.net/ui/vault/auth/oidc/oidc/callback",
      "https://hcvault.mattgerega.net/oidc/callback",
      "http://localhost:8250/oidc/callback"
    ]
    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }
}

resource "azuread_service_principal" "hcvault" {
  client_id                    = azuread_application.hcvault.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_user.owner.object_id]
  tags                         = ["WindowsAzureActiveDirectoryIntegratedApp"]
}

# Overlapping rotation: two passwords with staggered 30-day rotation.
# At most one password rotates at a time; the other remains valid.

moved {
  from = time_rotating.hcvault
  to   = time_rotating.hcvault-a
}

moved {
  from = azuread_application_password.hcvault
  to   = azuread_application_password.hcvault-a
}

resource "time_rotating" "hcvault-a" {
  rotation_days = local.rotation_days
  rfc3339       = time_static.rotation_base.rfc3339
}

resource "time_rotating" "hcvault-b" {
  rotation_days = local.rotation_days
  rfc3339       = timeadd(time_static.rotation_base.rfc3339, local.offset)
}

resource "azuread_application_password" "hcvault-a" {
  application_id      = azuread_application.hcvault.id
  display_name        = "Terraform-managed OIDC client secret"
  rotate_when_changed = {
    rotation = time_rotating.hcvault-a.id
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "azuread_application_password" "hcvault-b" {
  application_id      = azuread_application.hcvault.id
  display_name        = "Terraform-managed OIDC client secret"
  rotate_when_changed = {
    rotation = time_rotating.hcvault-b.id
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "vault_jwt_auth_backend" "oidc" {
  description        = "Azure AD OIDC authentication"
  path               = "oidc"
  type               = "oidc"
  oidc_discovery_url = "https://login.microsoftonline.com/${var.azure_directory_id}/v2.0"
  oidc_client_id     = azuread_application.hcvault.client_id
  oidc_client_secret = local.hcvault_primary
  default_role       = "aad-role"
}

resource "vault_jwt_auth_backend_role" "aad_role" {
  backend   = vault_jwt_auth_backend.oidc.path
  role_name = "aad-role"
  role_type = "oidc"

  user_claim   = "sub"
  groups_claim = "groups"
  oidc_scopes  = ["https://graph.microsoft.com/.default"]

  token_policies = ["default"]

  allowed_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "https://hcvault.mattgerega.net/ui/vault/auth/oidc/oidc/callback",
  ]
}

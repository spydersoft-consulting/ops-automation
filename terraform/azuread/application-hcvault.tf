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

resource "time_rotating" "hcvault" {
  rotation_days = 7
}

resource "azuread_service_principal_password" "hcvault" {
  service_principal_id = azuread_service_principal.hcvault.id
  rotate_when_changed = {
    rotation = time_rotating.hcvault.id
  }
}
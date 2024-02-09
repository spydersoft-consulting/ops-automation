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
      "https://hcvault.mattgerega.net/oidc/callback"
    ]
    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }
}
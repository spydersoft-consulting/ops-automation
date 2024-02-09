resource "azuread_application" "minio" {
  display_name = "MinIO"
  optional_claims {
    access_token {
        essential = false
        name = "groups"
        additional_properties = []
    }
    id_token {
        essential = false
        name = "groups"
        additional_properties = []
    }
    saml2_token {
        essential = false
        name = "groups"
        additional_properties = []
    }
  }
  group_membership_claims = ["All"]
  required_resource_access {
    resource_app_id = data.azuread_service_principal.graph.client_id
    resource_access {
        id = data.azuread_service_principal.graph.oauth2_permission_scope_ids["User.Read"] #"e1fe6dd8-ba31-4d61-89e7-88639da4683d"
        type = "Scope"
    }
  }
  web {
    redirect_uris = ["https://storage.mattgerega.net/oauth_callback"]
    implicit_grant {
        access_token_issuance_enabled = true
        id_token_issuance_enabled = true
    }
  }
}
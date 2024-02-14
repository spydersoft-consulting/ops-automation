resource "azuread_application" "argocd" {
  display_name            = "Argo CD"
  group_membership_claims = ["All"]
  identifier_uris         = ["https://argo.mattgerega.net/api/dex/callback"]

  api {
    requested_access_token_version = 1
    mapped_claims_enabled          = false
    known_client_applications      = []
    oauth2_permission_scope {
      id                         = "5ef97bbd-845b-4c81-b910-bf4c5fbf80ba"
      admin_consent_description  = "Allow the application to access Argo CD on behalf of the signed-in user."
      admin_consent_display_name = "Access Argo CD"
      enabled                    = true
      type                       = "User"
      value                      = "user_impersonation"
      user_consent_description   = "Allow the application to access Argo CD on your behalf."
      user_consent_display_name  = "Access Argo CD"
    }
  }
  app_role {
    allowed_member_types = ["User"]
    description          = "User"
    display_name         = "User"
    enabled              = true
    id                   = "18d14569-c3bd-439b-9a66-3a2aee01d14f"
  }
  app_role {
    allowed_member_types = ["User"]
    description          = "msiam_access"
    display_name         = "msiam_access"
    enabled              = true
    id                   = "b9632174-c057-4f7e-951b-be3adc52bfe6"
  }
  optional_claims {
    saml2_token {
      additional_properties = []
      essential             = false
      name                  = "groups"
    }
  }

  web {
    homepage_url  = "https://account.activedirectory.windowsazure.com:444/applications/default.aspx?metadata=customappsso|ISV9.1|primary|z"
    redirect_uris = ["https://argo.mattgerega.net/api/dex/callback"]
    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }
}

resource "azuread_service_principal" "argocd" {
  client_id                     = azuread_application.argocd.client_id
  app_role_assignment_required  = true
  login_url                     = "https://argo.mattgerega.net/auth/login"
  owners                        = [data.azuread_user.owner.object_id]
  preferred_single_sign_on_mode = "saml"
  notification_email_addresses  = ["geregam@outlook.com"]
  tags                          = ["WindowsAzureActiveDirectoryCustomSingleSignOnApplication", "WindowsAzureActiveDirectoryIntegratedApp"]
}

resource "time_rotating" "argocd" {
  rotation_days = 7
}

resource "azuread_service_principal_password" "argocd" {
  service_principal_id = azuread_service_principal.argocd.object_id
  rotate_when_changed = {
    rotation = time_rotating.argocd.id
  }
}

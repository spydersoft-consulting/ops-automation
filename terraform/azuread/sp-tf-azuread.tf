resource "azuread_application" "tf-azuread" {
  display_name     = "terraform-azuread-sp"
  owners           = [data.azuread_user.owner.object_id]
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"

  api {
    known_client_applications      = []
    mapped_claims_enabled          = false
    requested_access_token_version = 2
  }
}

resource "azuread_service_principal" "tf-azuread" {
  client_id                    = azuread_application.tf-azuread.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_user.owner.object_id]
}

resource "time_rotating" "tf-azuread" {
  rotation_days = 7
}

resource "azuread_service_principal_password" "tf-azuread" {
  service_principal_id = azuread_service_principal.tf-azuread.id
  rotate_when_changed = {
    rotation = time_rotating.tf-azuread.id
  }
}


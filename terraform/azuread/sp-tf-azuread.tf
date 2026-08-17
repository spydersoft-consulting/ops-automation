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

# This SP authenticates the pipeline that applies this very config, so its
# password must NOT auto-rotate: a rotation here would invalidate the
# credential the pipeline just used to authenticate, and nothing else
# writes the new value back into the Azure DevOps variable group the
# pipeline reads from at run start. Rotate this one manually/out-of-band
# when needed.
resource "azuread_service_principal_password" "tf-azuread" {
  service_principal_id = azuread_service_principal.tf-azuread.id
}

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

# Overlapping rotation: two passwords with staggered 30-day rotation.
# At most one password rotates at a time; the other remains valid.

moved {
  from = time_rotating.tf-azuread
  to   = time_rotating.tf-azuread-a
}

moved {
  from = azuread_service_principal_password.tf-azuread
  to   = azuread_service_principal_password.tf-azuread-a
}

resource "time_rotating" "tf-azuread-a" {
  rotation_days = local.rotation_days
  rfc3339       = time_static.rotation_base.rfc3339
}

resource "time_rotating" "tf-azuread-b" {
  rotation_days = local.rotation_days
  rfc3339       = timeadd(time_static.rotation_base.rfc3339, local.offset)
}

resource "azuread_service_principal_password" "tf-azuread-a" {
  service_principal_id = azuread_service_principal.tf-azuread.id
  rotate_when_changed = {
    rotation = time_rotating.tf-azuread-a.id
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "azuread_service_principal_password" "tf-azuread-b" {
  service_principal_id = azuread_service_principal.tf-azuread.id
  rotate_when_changed = {
    rotation = time_rotating.tf-azuread-b.id
  }
  lifecycle {
    create_before_destroy = true
  }
}

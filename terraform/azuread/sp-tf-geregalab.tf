resource "azuread_application" "tf-gerega-lab" {
  display_name = "terraform-gerega-lab"
  owners       = [data.azuread_user.owner.object_id]
}

resource "azuread_service_principal" "tf-gerega-lab" {
  client_id                    = azuread_application.tf-gerega-lab.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_user.owner.object_id]
}

resource "time_rotating" "tf-gerega-lab" {
  rotation_days = 7
}

resource "azuread_service_principal_password" "tf-gerega-lab" {
  service_principal_id = azuread_service_principal.tf-gerega-lab.object_id
  rotate_when_changed = {
    rotation = time_rotating.tf-gerega-lab.id
  }
}


resource "azuread_application" "tf-gerega-lab" {
  display_name = "terraform-gerega-lab"
  owners       = [data.azuread_user.owner.object_id]
}

resource "azuread_service_principal" "tf-gerega-lab" {
  client_id                    = azuread_application.tf-gerega-lab.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_user.owner.object_id]
}

# Overlapping rotation: two passwords with staggered 30-day rotation.
# At most one password rotates at a time; the other remains valid.

moved {
  from = time_rotating.tf-gerega-lab
  to   = time_rotating.tf-gerega-lab-a
}

moved {
  from = azuread_service_principal_password.tf-gerega-lab
  to   = azuread_service_principal_password.tf-gerega-lab-a
}

resource "time_rotating" "tf-gerega-lab-a" {
  rotation_days = local.rotation_days
  rfc3339       = time_static.rotation_base.rfc3339
}

resource "time_rotating" "tf-gerega-lab-b" {
  rotation_days = local.rotation_days
  rfc3339       = timeadd(time_static.rotation_base.rfc3339, local.offset)
}

resource "azuread_service_principal_password" "tf-gerega-lab-a" {
  service_principal_id = azuread_service_principal.tf-gerega-lab.id
  rotate_when_changed = {
    rotation = time_rotating.tf-gerega-lab-a.id
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "azuread_service_principal_password" "tf-gerega-lab-b" {
  service_principal_id = azuread_service_principal.tf-gerega-lab.id
  rotate_when_changed = {
    rotation = time_rotating.tf-gerega-lab-b.id
  }
  lifecycle {
    create_before_destroy = true
  }
}

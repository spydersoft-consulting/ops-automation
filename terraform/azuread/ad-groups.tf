
resource "azuread_group" "argo-admins" {
  display_name     = "argo-admins"
  description      = "Administrators for ArgoCD"
  security_enabled = true
  owners           = [data.azuread_user.owner.object_id]
  members          = [data.azuread_user.owner.object_id]
}

resource "azuread_group" "vault-admins" {
  display_name     = "vault-admins"
  description      = "Administrators for HC Vault"
  security_enabled = true
  owners           = [data.azuread_user.owner.object_id]
  members          = [data.azuread_user.owner.object_id]
}
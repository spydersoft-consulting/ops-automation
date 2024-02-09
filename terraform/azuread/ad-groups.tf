resource "azuread_group" "minio-admins" {
    display_name        = "minio-admins"
    description         = "Administrators for MinIO"
    security_enabled    = true
    owners = [ data.azuread_user.owner.object_id ]
    members = [ data.azuread_user.owner.object_id ]
}

resource "azuread_group" "argo-admins" {
    display_name        = "argo-admins"
    description         = "Administrators for ArgoCD"
    security_enabled    = true
    owners = [ data.azuread_user.owner.object_id ]
    members = [ data.azuread_user.owner.object_id ]
}
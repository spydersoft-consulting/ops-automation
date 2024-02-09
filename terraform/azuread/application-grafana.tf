resource "azuread_application" "grafana" {
  display_name = "Grafana"
  owners = [ data.azuread_user.owner.object_id ]
  app_role {
    allowed_member_types = [ "User" ]
    description = "Grafana Editor Users"
    display_name = "Grafana Editor"
    enabled = true
    id = "010271dc-4c53-4678-99af-259b22a68e43"
    value = "Editor"
  }
  app_role {
    allowed_member_types = [ "User" ]
    description = "Grafana admin Users"
    display_name = "Grafana Admin"
    enabled = true
    id = "7907720c-5371-47e5-a1b5-13e87da4ebea"
    value = "Admin"
  }
  app_role {
    allowed_member_types = [ "User" ]
    description = "Grafana read only Users"
    display_name = "Grafana Viewer"
    enabled = true
    id = "9343cad0-02f9-4d5f-af25-45d36334a812"
    value = "Viewer"
  }

  required_resource_access {
    resource_app_id = data.azuread_service_principal.graph.client_id
    resource_access {
        id = data.azuread_service_principal.graph.oauth2_permission_scope_ids["User.Read"] #"e1fe6dd8-ba31-4d61-89e7-88639da4683d"
        type = "Scope"
    }
  }

  web {
    redirect_uris = ["https://grafana.mattgerega.net/", "https://grafana.mattgerega.net/login/azuread"]
    implicit_grant {
        access_token_issuance_enabled = false
        id_token_issuance_enabled = false
    }
  }
}
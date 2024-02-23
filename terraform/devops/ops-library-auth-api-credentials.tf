resource "azuredevops_variable_group" "auth-api-credentials" {
  project_id   = azuredevops_project.ops.id
  name         = "auth-api-credentials"
  description  = "[terraform-managed] Credentials for the Central Authentication API"
  allow_access = false

  variable {
    name  = "auth-url"
    value = data.vault_kv_secret_v2.mg-authentication.data["authUrl"]
  }

  variable {
    name         = "auth-client-id"
    value = data.vault_kv_secret_v2.mg-authentication.data["clientId"]
  }

  variable {
    name         = "auth-client-secret"
    secret_value = data.vault_kv_secret_v2.mg-authentication.data["clientSecret"]
    is_secret    = true
  }

  variable {
    name         = "auth-username"
    value = data.vault_kv_secret_v2.mg-authentication.data["username"]
  }

  variable {
    name         = "auth-password"
    secret_value = data.vault_kv_secret_v2.mg-authentication.data["password"]
    is_secret    = true
  }

}
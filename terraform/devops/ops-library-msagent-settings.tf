resource "azuredevops_variable_group" "ms-agent-settings" {
  project_id   = azuredevops_project.ops.id
  name         = "ms-agent-settings"
  description  = "[terraform-managed] MS Agent Settings"
  allow_access = false

  variable {
    name  = "agent-org"
    value = data.vault_kv_secret_v2.azure-agent-settings.data["agent_org"]
  }

  variable {
    name  = "agent-username"
    value = data.vault_kv_secret_v2.azure-agent-settings.data["agent_username"]
  }

  variable {
    name  = "devops-username"
    value = data.vault_kv_secret_v2.azure-agent-settings.data["devops_username"]
  }

  variable {
    name         = "agent-password"
    secret_value = data.vault_kv_secret_v2.azure-agent-settings.data["agent_password"]
    is_secret    = true
  }

  variable {
    name         = "agent-pat"
    secret_value = data.vault_kv_secret_v2.azure-agent-settings.data["agent_pat"]
    is_secret    = true
  }

  variable {
    name         = "authorized-keys"
    secret_value = data.vault_kv_secret_v2.authorized-keys.data["data"]
    is_secret    = true
  }

  variable {
    name  = "unifi-wrapper-url"
    value = var.unifi_wrapper_url
  }
  variable {
    name  = "unifi-provisioning-group"
    value = var.unifi_provisioning_group
  }
}
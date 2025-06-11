resource "azuredevops_variable_group" "proxmox-settings" {
  project_id   = azuredevops_project.ops.id
  name         = "proxmox-settings"
  description  = "[terraform-managed] Proxmox Settings"
  allow_access = false

  variable {
    name  = "proxmox-host"
    value = data.vault_kv_secret_v2.proxmox-settings.data["host"]
  }

  variable {
    name  = "proxmox-api-token"
    value = data.vault_kv_secret_v2.proxmox-settings.data["apiToken"]
  }
}
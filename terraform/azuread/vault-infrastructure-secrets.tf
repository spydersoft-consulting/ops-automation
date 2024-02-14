resource "vault_kv_secret_v2" "geregalab-tf-sp" {
  mount               = "secrets-infra"
  name                = "azure/service-principals/terraform-gerega-lab-sp"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      appId     = azuread_service_principal.tf-gerega-lab.client_id
      tenant_id = var.azure_directory_id
      password  = azuread_service_principal_password.tf-gerega-lab.value
    }
  )
}

resource "vault_kv_secret_v2" "azuread-tf-sp" {
  mount               = "secrets-infra"
  name                = "azure/service-principals/terraform-azuread-sp"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      appId     = azuread_service_principal.tf-azuread.client_id
      tenant_id = var.azure_directory_id
      password  = azuread_service_principal_password.tf-azuread.value
    }
  )
}

resource "vault_kv_secret_v2" "grafana-app" {
  mount               = "secrets-infra"
  name                = "azure/applications/grafana"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      appId     = azuread_service_principal.grafana.client_id
      tenant_id = var.azure_directory_id
      password  = azuread_service_principal_password.grafana.value
    }
  )
}

resource "vault_kv_secret_v2" "argocd-app" {
  mount               = "secrets-infra"
  name                = "azure/applications/argocd"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      appId     = azuread_service_principal.argocd.client_id
      tenant_id = var.azure_directory_id
      password  = azuread_service_principal_password.argocd.value
    }
  )
}

resource "vault_kv_secret_v2" "hcvault-app" {
  mount               = "secrets-infra"
  name                = "azure/applications/hcvault"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      appId     = azuread_service_principal.hcvault.client_id
      tenant_id = var.azure_directory_id
      password  = azuread_service_principal_password.hcvault.value
    }
  )
}

resource "vault_kv_secret_v2" "minio-app" {
  mount               = "secrets-infra"
  name                = "azure/applications/minio"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      appId     = azuread_service_principal.minio.client_id
      tenant_id = var.azure_directory_id
      password  = azuread_service_principal_password.minio.value
    }
  )
}
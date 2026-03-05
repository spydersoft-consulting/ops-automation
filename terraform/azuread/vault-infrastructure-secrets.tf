resource "vault_kv_secret_v2" "geregalab-tf-sp" {
  mount = "secrets-infra"
  name  = "azure/service-principals/terraform-gerega-lab-sp"
  data_json = jsonencode(
    {
      appId              = azuread_service_principal.tf-gerega-lab.client_id
      tenant_id          = var.azure_directory_id
      password           = local.tf_geregalab_primary
      password_secondary = local.tf_geregalab_secondary
    }
  )
}

resource "vault_kv_secret_v2" "azuread-tf-sp" {
  mount = "secrets-infra"
  name  = "azure/service-principals/terraform-azuread-sp"
  data_json = jsonencode(
    {
      appId              = azuread_service_principal.tf-azuread.client_id
      tenant_id          = var.azure_directory_id
      password           = local.tf_azuread_primary
      password_secondary = local.tf_azuread_secondary
    }
  )
}

resource "vault_kv_secret_v2" "grafana-app" {
  mount = "secrets-infra"
  name  = "azure/applications/grafana"
  data_json = jsonencode(
    {
      appId              = azuread_application.grafana.client_id
      tenant_id          = var.azure_directory_id
      password           = local.grafana_primary
      password_secondary = local.grafana_secondary
    }
  )
}

resource "vault_kv_secret_v2" "argocd-app" {
  mount = "secrets-infra"
  name  = "azure/applications/argocd"
  data_json = jsonencode(
    {
      appId              = azuread_application.argocd.client_id
      tenant_id          = var.azure_directory_id
      password           = local.argocd_primary
      password_secondary = local.argocd_secondary
    }
  )
}

resource "vault_kv_secret_v2" "hcvault-app" {
  mount = "secrets-infra"
  name  = "azure/applications/hcvault"
  data_json = jsonencode(
    {
      appId              = azuread_application.hcvault.client_id
      tenant_id          = var.azure_directory_id
      password           = local.hcvault_primary
      password_secondary = local.hcvault_secondary
    }
  )
}

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
data "vault_kv_secret_v2" "geregalab-tf-sp" {
  mount               = "secrets-infra"
  name                = "azure/service-principals/terraform-gerega-lab-sp"
}

data "vault_kv_secret_v2" "azuread-tf-sp" {
  mount               = "secrets-infra"
  name                = "azure/service-principals/terraform-azuread-sp"
}
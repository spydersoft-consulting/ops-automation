data "vault_kv_secret_v2" "geregalab-tf-sp" {
  mount = "secrets-infra"
  name  = "azure/service-principals/terraform-gerega-lab-sp"
}

data "vault_kv_secret_v2" "azuread-tf-sp" {
  mount = "secrets-infra"
  name  = "azure/service-principals/terraform-azuread-sp"
}

data "vault_kv_secret_v2" "devops-tf" {
  mount = "secrets-infra"
  name  = "azure/devops"
}
data "vault_kv_secret_v2" "vault-app-role" {
  mount = "secrets-infra"
  name  = "hcvault/approle/terraform-approle"
}
data "vault_kv_secret_v2" "s3-backend" {
  mount = "secrets-infra"
  name  = "minio/terraform-access"
}

data "vault_kv_secret_v2" "spydersoft-gh-token" {
  mount = "secrets-infra"
  name  = "github/spydersoft-ado"
}

data "vault_kv_secret_v2" "sonarqube-ado-public-projects" {
  mount = "secrets-infra"
  name  = "sonarqube/ado-public-projects"
}

data "vault_kv_secret_v2" "proget-nuget" {
  mount = "secrets-infra"
  name  = "proget/nuget"
}

data "vault_kv_secret_v2" "proget-docker" {
  mount = "secrets-infra"
  name  = "proget/docker"
}

data "vault_kv_secret_v2" "k8-nonprod-kubeconfig" {
  mount = "secrets-infra"
  name  = "kubernetes/nonproduction/kubeconfig"
}

data "vault_kv_secret_v2" "k8-prod-kubeconfig" {
  mount = "secrets-infra"
  name  = "kubernetes/production/kubeconfig"
}

data "vault_kv_secret_v2" "mg-authentication" {
  mount = "secrets-infra"
  name  = "mattgerega/authentication/ro_client"
}
data "vault_kv_secret_v2" "azure-agent-settings" {
  mount = "secrets-infra"
  name  = "azure/buildagent/ubuntu"
}
data "vault_kv_secret_v2" "authorized-keys" {
  mount = "secrets-infra"
  name  = "access/authorized_keys"
}

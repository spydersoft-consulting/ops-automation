data "vault_kv_secret_v2" "github-terraform" {
  mount = "secrets-infra"
  name  = "github/terraform"
}

data "vault_kv_secret_v2" "github-sonar" {
  mount = "secrets-infra"
  name  = "github/sonar"
}

data "vault_kv_secret_v2" "github-pypi" {
  mount = "secrets-infra"
  name  = "github/pypi"
}

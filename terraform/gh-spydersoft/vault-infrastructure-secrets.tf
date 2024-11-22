data "vault_kv_secret_v2" "github-terraform" {
  mount = "secrets-infra"
  name  = "github/terraform"
}

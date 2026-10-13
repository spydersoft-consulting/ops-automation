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

data "vault_kv_secret_v2" "github-nuget-org" {
  mount = "secrets-infra"
  name  = "github/nuget-org"
}

# GPG key used to sign Terraform/OpenTofu provider releases. Expected fields:
# private (ASCII-armored secret key), public (ASCII-armored public key) and
# passphrase (the secret key is passphrase-protected).
data "vault_kv_secret_v2" "terraform-signing" {
  mount = "secrets-infra"
  name  = "terraform/signing"
}

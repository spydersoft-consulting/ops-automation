terraform {
  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}


provider "vault" {
  address          = "https://hcvault.mattgerega.net"
  skip_child_token = true
  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = var.vault_approle_role_id
      secret_id = var.vault_approle_secret_id
    }
  }
}
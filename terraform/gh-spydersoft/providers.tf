terraform {
  required_providers {
    azurerm = {
      source = "integrations/github"
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

provider "github" {
  owner = "spydersoft-consulting"
  #token = var.github_token
}
terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
    time = {
      source = "hashicorp/time"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azuread" {
  tenant_id = var.azure_directory_id
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
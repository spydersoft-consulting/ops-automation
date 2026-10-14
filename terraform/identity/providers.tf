terraform {
  required_providers {
    # Not published to a registry: the pipeline installs the release from
    # GitHub into terraform.d/plugins (see .devops/template-install-local-providers.yaml).
    # Bump the version here AND in .devops/pipeline-tf-identity.yaml together.
    spydersoftidentity = {
      source  = "spydersoft-consulting/spydersoft-identity"
      version = "0.2.0"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

# In the pipeline the AppRole variables are set. Locally leave them empty and
# the provider uses your Vault CLI login (VAULT_TOKEN or ~/.vault-token).
provider "vault" {
  address          = "https://hcvault.mattgerega.net"
  skip_child_token = true

  dynamic "auth_login" {
    for_each = var.vault_approle_role_id == "" ? [] : [1]
    content {
      path = "auth/approle/login"

      parameters = {
        role_id   = var.vault_approle_role_id
        secret_id = var.vault_approle_secret_id
      }
    }
  }
}

provider "spydersoftidentity" {
  url           = var.admin_api_url
  token_url     = var.token_url
  client_id     = data.vault_kv_secret_v2.provider_credentials.data["clientId"]
  client_secret = data.vault_kv_secret_v2.provider_credentials.data["clientSecret"]
}

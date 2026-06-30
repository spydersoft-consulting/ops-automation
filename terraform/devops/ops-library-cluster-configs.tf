resource "azuredevops_variable_group" "cluster-nonprod" {
  project_id   = azuredevops_project.ops.id
  name         = "cluster-nonprod"
  description  = "[terraform-managed] Nonprod cluster credentials for cycling pipeline"
  allow_access = false

  variable {
    name         = "kubeconfig"
    secret_value = data.vault_kv_secret_v2.k8-nonprod-kubeconfig.data["kubeconfig"]
    is_secret    = true
  }

  variable {
    name         = "node-token"
    secret_value = data.vault_kv_secret_v2.k8-nonprod-node-token.data["token"]
    is_secret    = true
  }
}

resource "azuredevops_variable_group" "cluster-internal" {
  project_id   = azuredevops_project.ops.id
  name         = "cluster-internal"
  description  = "[terraform-managed] Internal cluster credentials for cycling pipeline"
  allow_access = false

  variable {
    name         = "kubeconfig"
    secret_value = data.vault_kv_secret_v2.k8-internal-kubeconfig.data["kubeconfig"]
    is_secret    = true
  }

  variable {
    name         = "node-token"
    secret_value = data.vault_kv_secret_v2.k8-internal-node-token.data["token"]
    is_secret    = true
  }
}

resource "azuredevops_variable_group" "cluster-prod" {
  project_id   = azuredevops_project.ops.id
  name         = "cluster-prod"
  description  = "[terraform-managed] Production cluster credentials for cycling pipeline"
  allow_access = false

  variable {
    name         = "kubeconfig"
    secret_value = data.vault_kv_secret_v2.k8-prod-kubeconfig.data["kubeconfig"]
    is_secret    = true
  }

  variable {
    name         = "node-token"
    secret_value = data.vault_kv_secret_v2.k8-prod-node-token.data["token"]
    is_secret    = true
  }
}

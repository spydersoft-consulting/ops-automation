resource "azuredevops_agent_pool" "default" {
  name           = "Default"
  auto_provision = true
  auto_update    = true
}

resource "azuredevops_agent_pool" "provisioning" {
  name           = "Provisioning"
  auto_provision = false
  auto_update    = true
}

resource "azuredevops_agent_pool" "azure" {
  name           = "Azure Pipelines"
  auto_provision = true
  auto_update    = true
}
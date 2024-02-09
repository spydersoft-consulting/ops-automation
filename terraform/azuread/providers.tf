terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azuread" {
  tenant_id = var.azure_directory_id
}
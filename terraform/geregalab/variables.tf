variable "azure_directory_id" {
  description = "Microsoft Entra Directory ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "vault_approle_role_id" {
  description = "Vault AppRole Role ID"
  type        = string
  sensitive   = true
}

variable "vault_approle_secret_id" {
  description = "Vault AppRole Secret ID"
  type        = string
  sensitive   = true
}

variable "vault_autounseal_client_id" {
  description = "Client ID of the Vault auto-unseal service principal (from azuread terraform)"
  type        = string
}

variable "terraform_gerega_lab_sp_client_id" {
  description = "Client ID of the Terraform Gerega Lab service principal (from azuread terraform)"
  type        = string
}
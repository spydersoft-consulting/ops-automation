
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
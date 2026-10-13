variable "environment" {
  description = "Environment name; selects the Vault credentials."
  type        = string

  validation {
    condition     = contains(["test", "production"], var.environment)
    error_message = "environment must be \"test\" or \"production\"."
  }
}

variable "admin_api_url" {
  description = "Base URL of the identity server admin API."
  type        = string
}

variable "token_url" {
  description = "OAuth2 token endpoint of the identity server."
  type        = string
}

variable "vault_approle_role_id" {
  description = "Vault AppRole Role ID. Empty (local runs) means use the Vault CLI login."
  type        = string
  sensitive   = true
  default     = ""
}

variable "vault_approle_secret_id" {
  description = "Vault AppRole Secret ID. Empty (local runs) means use the Vault CLI login."
  type        = string
  sensitive   = true
  default     = ""
}

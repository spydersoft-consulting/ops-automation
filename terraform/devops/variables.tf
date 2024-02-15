
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

variable "minio_address" {
  description = "MinIO Address"
  type        = string
}

variable "git_email" {
  description = "Email Address associated with Git commits"
  type        = string
}

variable "git_name" {
  description = "Name associated with Git commits"
  type        = string
}
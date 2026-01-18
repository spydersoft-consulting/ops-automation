variable "github_token" {
  description = "Github PAT"
  type        = string
  sensitive   = true
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

variable "sonar_token_repositories" {
  description = "List of repositories to add the SONAR_TOKEN secret"
  type        = list(string)
}
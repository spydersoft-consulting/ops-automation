# Names match the ARM_* variables in the "terraform-azuread" ADO variable
# group so the generic sync step in template-terraform.yaml can push them
# back verbatim after apply.
output "ARM_CLIENT_ID" {
  value = azuread_service_principal.tf-azuread.client_id
}

output "ARM_TENANT_ID" {
  value = var.azure_directory_id
}

output "ARM_CLIENT_SECRET" {
  value     = azuread_service_principal_password.tf-azuread.value
  sensitive = true
}

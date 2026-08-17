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

# terraform-gerega-lab SP's password still auto-rotates (it authenticates a
# different, unrelated pipeline, not this one), so its ADO variable group
# needs the same after-apply sync to avoid going stale on rotation.
output "GEREGALAB_ARM_CLIENT_ID" {
  value = azuread_service_principal.tf-gerega-lab.client_id
}

output "GEREGALAB_ARM_TENANT_ID" {
  value = var.azure_directory_id
}

output "GEREGALAB_ARM_CLIENT_SECRET" {
  value     = local.tf_geregalab_primary
  sensitive = true
}

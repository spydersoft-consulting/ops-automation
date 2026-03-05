resource "time_static" "rotation_base" {}

locals {
  rotation_days = 30
  offset        = "360h" # 15 days

  # For each SP/app, select the most recently rotated password as primary.
  # The password with the LATER next-rotation was rotated more recently
  # and has the longest remaining validity.

  # terraform-azuread SP
  tf_azuread_primary = (
    timecmp(time_rotating.tf-azuread-a.rotation_rfc3339, time_rotating.tf-azuread-b.rotation_rfc3339) >= 0
    ? azuread_service_principal_password.tf-azuread-a.value
    : azuread_service_principal_password.tf-azuread-b.value
  )
  tf_azuread_secondary = (
    timecmp(time_rotating.tf-azuread-a.rotation_rfc3339, time_rotating.tf-azuread-b.rotation_rfc3339) >= 0
    ? azuread_service_principal_password.tf-azuread-b.value
    : azuread_service_principal_password.tf-azuread-a.value
  )

  # terraform-gerega-lab SP
  tf_geregalab_primary = (
    timecmp(time_rotating.tf-gerega-lab-a.rotation_rfc3339, time_rotating.tf-gerega-lab-b.rotation_rfc3339) >= 0
    ? azuread_service_principal_password.tf-gerega-lab-a.value
    : azuread_service_principal_password.tf-gerega-lab-b.value
  )
  tf_geregalab_secondary = (
    timecmp(time_rotating.tf-gerega-lab-a.rotation_rfc3339, time_rotating.tf-gerega-lab-b.rotation_rfc3339) >= 0
    ? azuread_service_principal_password.tf-gerega-lab-b.value
    : azuread_service_principal_password.tf-gerega-lab-a.value
  )

  # Argo CD application
  argocd_primary = (
    timecmp(time_rotating.argocd-a.rotation_rfc3339, time_rotating.argocd-b.rotation_rfc3339) >= 0
    ? azuread_application_password.argocd-a.value
    : azuread_application_password.argocd-b.value
  )
  argocd_secondary = (
    timecmp(time_rotating.argocd-a.rotation_rfc3339, time_rotating.argocd-b.rotation_rfc3339) >= 0
    ? azuread_application_password.argocd-b.value
    : azuread_application_password.argocd-a.value
  )

  # Grafana application
  grafana_primary = (
    timecmp(time_rotating.grafana-a.rotation_rfc3339, time_rotating.grafana-b.rotation_rfc3339) >= 0
    ? azuread_application_password.grafana-a.value
    : azuread_application_password.grafana-b.value
  )
  grafana_secondary = (
    timecmp(time_rotating.grafana-a.rotation_rfc3339, time_rotating.grafana-b.rotation_rfc3339) >= 0
    ? azuread_application_password.grafana-b.value
    : azuread_application_password.grafana-a.value
  )

  # HC Vault application
  hcvault_primary = (
    timecmp(time_rotating.hcvault-a.rotation_rfc3339, time_rotating.hcvault-b.rotation_rfc3339) >= 0
    ? azuread_application_password.hcvault-a.value
    : azuread_application_password.hcvault-b.value
  )
  hcvault_secondary = (
    timecmp(time_rotating.hcvault-a.rotation_rfc3339, time_rotating.hcvault-b.rotation_rfc3339) >= 0
    ? azuread_application_password.hcvault-b.value
    : azuread_application_password.hcvault-a.value
  )

}

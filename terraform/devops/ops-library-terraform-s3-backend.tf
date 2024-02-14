resource "azuredevops_variable_group" "terraform-s3-backend" {
  project_id   = azuredevops_project.ops.id
  name         = "terraform-s3-backend"
  description  = "[terraform-managed] MinIO S3 Credentials"
  allow_access = false

  variable {
    name  = "AWS_ACCESS_KEY_ID"
    secret_value = data.vault_kv_secret_v2.s3-backend.data["access_key"]
    is_secret    = true
  }

    variable {
    name  = "AWS_SECRET_ACCESS_KEY"
    secret_value = data.vault_kv_secret_v2.s3-backend.data["secret_key"]
    is_secret    = true
  }

  variable {
    name         = "AWS_ENDPOINT_URL_S3"
    value = var.minio_address
  }

}
# Partial backend configuration: the state key is supplied per environment at
# init time, so test and production never share a state file:
#   tofu init -backend-config="key=identity/test/terraform.tfstate"
#   tofu init -backend-config="key=identity/production/terraform.tfstate" -reconfigure
terraform {
  backend "s3" {
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
    bucket                      = "terraform"
    region                      = "us-east-1"
  }
}


param (
    [bool]$forAzureAd = $false
)

function Get-VaultData {
    param (
        [string]$path
    )
    $vaultData = vault kv get -format=json $path | ConvertFrom-Json
    return $vaultData.data.data
}


# TODO: Verify vault CLI logged in

$garageAwsCredentials = Get-VaultData -path "secrets-infra/garage/terraform-access"

$env:AWS_ACCESS_KEY_ID = $garageAwsCredentials.access_key
$env:AWS_SECRET_ACCESS_KEY = $garageAwsCredentials.secret_key
$env:AWS_ENDPOINT_URL_S3 = $garageAwsCredentials.url
              
$adoCreds = Get-VaultData -path "secrets-infra/azure/devops"

$env:AZDO_PERSONAL_ACCESS_TOKEN = $adoCreds.access_token
$env:AZDO_ORG_SERVICE_URL = $adoCreds.service_url

if ($forAzureAd) {
    $armCreds = Get-VaultData -path "secrets-infra/azure/service-principals/terraform-azuread-sp"
}
else {
    $armCreds = Get-VaultData -path "secrets-infra/azure/service-principals/terraform-gerega-lab-sp"
}

$env:ARM_CLIENT_ID = $armCreds.appId
$env:ARM_CLIENT_SECRET = $armCreds.password
$env:ARM_TENANT_ID = $armCreds.tenant_id

$githubCreds = Get-VaultData -path "secrets-infra/github/terraform"
$env:GITHUB_OWNER = $githubCreds.user
$env:GITHUB_TOKEN = $githubCreds.token

$vaultAppRole = Get-VaultData -path "secrets-infra/hcvault/approle/terraform-approle"
$env:TF_VAR_vault_approle_role_id = $vaultAppRole.app_role_id
$env:TF_VAR_vault_approle_secret_id = $vaultAppRole.secret_id
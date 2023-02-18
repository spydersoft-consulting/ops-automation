param (
    $appRole = "",
    $appRoleSecretId = "",
    $tokenAppRole = "",
    $tokenAppRoleSecretId = "",
    $vaultUrl = "",
    $kvName = "",
    $secretPath = "",
    $tokenKeyName = ""
)

# Perform a login using the tokenAppRole/tokenAppRoleSecretId to get a new token for this appRole

$tokenRefreshData = @{
    role_id = "$tokenAppRole"
    secret_id = "$tokenAppRoleSecretId"
}
$tokenAppRoleLoginResult = Invoke-RestMethod -Uri "$($vaultUrl)/v1/auth/approle/login" -Method Post -Body (ConvertTo-Json $tokenRefreshData)

$newToken = $tokenAppRoleLoginResult.auth.client_token

# Using the appRole/appRoleSecretId, get a token for writing the new secret into vault. 
$appRoleData = @{
    role_id = "$appRole"
    secret_id = "$appRoleSecretId"
}
$appRoleLoginResult = Invoke-RestMethod -Uri "$($vaultUrl)/v1/auth/approle/login" -Method Post -Body (ConvertTo-Json $appRoleData)

# Write the new secret to the kv/secretPath
$newSecretData = "
    {
        `"data`": {
            `"$tokenKeyName`": `"$newToken`"
        }
    }
"
$headers = @{
    'X-Vault-Token' = "$($appRoleLoginResult.auth.client_token)"
    'Content-Type' = "application/merge-patch+json"
}

$url = "$($vaultUrl)/v1/$($kvName)/data/$secretPath"
Invoke-RestMethod -Uri "$url" -Headers $headers -body $newSecretData -Method Patch
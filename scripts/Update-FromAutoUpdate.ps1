<#
    .SYNOPSIS
        Update the values.yaml file in this folder with a new image tag based on images from external sources

    .DESCRIPTION
        This script loads a file named `auto-update.json` from the folder and updates the `tagPath` in the values.yaml file
          with a new version.

        Currently this script supports checking for new release versions from a Github repository and using the tag_name from
        that release as the image tag in the values.yaml file.
        
        auto-update.json sample:
        {
            "repository": "redis-stack/redis-stack",
            "stripVFromVersion": false,
            "tagPath": "redis.image.tag"
        }


    .EXAMPLE
        Update-FromAutoUpdate -path c:\path\to\mychart -name mychart

    .PARAMETER path
        The path where the chart.yaml and values.yaml file exist.

    .PARAMETER name
        A descriptive name for the application, used in constructing a commit comment.
#>

param (
    $path,
    $name
)

Push-Location $path

if (-not (Test-Path "auto-update.json")) {
    Pop-Location
    return @{
        updated = $false
        comment = ""
    }
}
$updateFile = Get-ChildItem "auto-update.json" -ErrorAction SilentlyContinue;

$json = Get-Content $updateFile -Raw | ConvertFrom-Json

$latest = Invoke-RestMethod -Uri "https://api.github.com/repos/$($json.repository)/releases/latest"

$version = $latest.tag_name
if ($json.stripVFromVersion) {
    $version = $version.Trim("v");
}



$valuesYaml = Get-Content .\values.yaml -Raw | ConvertFrom-Yaml

# Get current tag value    
$expression = "`$valuesYaml.$($json.tagPath)"
$currentVersion = Invoke-Expression $expression

if ($null -eq $currentVersion) {
    Pop-Location
    return @{
        updated = $false
        comment = ""
    }
}

$versionV = New-Object "System.Management.Automation.SemanticVersion" $version.replace("v", "")
$currentV = New-Object "System.Management.Automation.SemanticVersion" $currentVersion.replace("v", "")
if ($currentV -ge $versionV) {
    Pop-Location
    return @{
        updated = $false
        comment = ""
    }
}

Write-Host "Updating $name : $currentVersion -> $version"
$commitComment += "Bump $name from $currentVersion to $version"
$expression = "`$valuesYaml.$($json.tagPath) = `"$version`""
Invoke-Expression $expression

ConvertTo-Yaml $valuesYaml | Set-Content .\values.yaml
Pop-Location
return @{
    updated = $true
    comment = $commitComment
}

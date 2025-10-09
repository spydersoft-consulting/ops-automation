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
        Update-HelmFromAutoUpdate -path c:\path\to\mychart -name mychart

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

$valuesYaml = Get-Content .\values.yaml -Raw | ConvertFrom-Yaml

$repositoryUpdated = $false

foreach ($repository in $json.repositories) {
    $type = "github"
    if ($null -ne $repository.type) {
        $type = $repository.type
    }

    if ($type -eq "github") {
        $latest = Invoke-RestMethod -Uri "https://api.github.com/repos/$($repository.repository)/releases/latest"

        $version = $latest.tag_name

        if ($null -ne $repository.imagePrefix) {
            if ($version.StartsWith($repository.imagePrefix)) {
                $version = $version.Substring($repository.imagePrefix.Length)
            }
        }

        $versionV = New-Object "System.Management.Automation.SemanticVersion" $version
    }
    elseif ($type -eq "docker") {
        
        $registryUrl = "https://registry.hub.docker.com/v2"
        if (-not [String]::IsNullOrWhiteSpace($repository.registryUrl)) {
            $registryUrl = $repository.registryUrl
        }

        $registryData = Invoke-RestMethod -Uri "$($registryUrl)/$($repository.repository)/tags/list"
        $versionV = $registryData.tags | Where-Object { $_ -NotLike "*-ci*" -and $_ -NotLike "*latest*" -and $_ -NotLike "*rc*" } | ForEach-Object { New-Object "System.Management.Automation.SemanticVersion" $_ } | Sort-Object -descending | Select-Object -First 1
        $version = $versionV.ToString()
    }

    # Get current tag value    
    $expression = "`$valuesYaml.$($repository.tagPath)"
    $currentVersion = Invoke-Expression $expression

    if ($null -eq $currentVersion) {
        continue
    }

    $currentV = New-Object "System.Management.Automation.SemanticVersion" $currentVersion.replace("v", "")
    if ($currentV -ge $versionV) {
        continue
    }

    Write-Host "Updating $name : $currentVersion -> $version"
    $commitComment += "Bump $name from $currentVersion to $version"

    $keepImagePrefixInVersion = $false
    if ($null -ne $repository.keepImagePrefix && $repository.keepImagePrefix -eq $true) {
        $keepImagePrefixInVersion = $repository.keepImagePrefix
    }

    if ($keepImagePrefixInVersion) {
        $version = "$($repository.imagePrefix)$($version)"
    }

    $expression = "`$valuesYaml.$($repository.tagPath) = `"$version`""
    Invoke-Expression $expression

    $repositoryUpdated = $true
}

if ($repositoryUpdated) {
    $commitComment = "Update $name to latest versions"
    ConvertTo-Yaml $valuesYaml | Set-Content .\values.yaml
}
else {
    $commitComment = "No updates found for $name"
}
Pop-Location
return @{
    updated = $repositoryUpdated
    comment = $commitComment
}

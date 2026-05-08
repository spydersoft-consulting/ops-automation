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
        if (-not [String]::IsNullOrWhiteSpace($repository.tagFilter)) {
            $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$($repository.repository)/releases?per_page=100"
            $prefix = if ($null -ne $repository.imagePrefix) { $repository.imagePrefix } else { "" }
            $candidate = $releases | Where-Object { $_.prerelease -eq $false -and $_.tag_name -match $repository.tagFilter } | ForEach-Object {
                $t = $_.tag_name
                if ($prefix -and $t.StartsWith($prefix)) { $t = $t.Substring($prefix.Length) }
                try { [PSCustomObject]@{ Tag = $_.tag_name; Version = $t; SemVer = New-Object "System.Management.Automation.SemanticVersion" $t } } catch { $null }
            } | Where-Object { $null -ne $_ } | Sort-Object -Property SemVer -Descending | Select-Object -First 1

            if ($null -eq $candidate) {
                Write-Host "No releases matched tagFilter '$($repository.tagFilter)' for $($repository.repository)"
                continue
            }
            $version = $candidate.Version
            $versionV = $candidate.SemVer
        }
        else {
            $latest = Invoke-RestMethod -Uri "https://api.github.com/repos/$($repository.repository)/releases/latest"

            $version = $latest.tag_name

            if ($latest.tag_name.Contains("beta") -or $latest.tag_name.Contains("alpha") -or $latest.tag_name.Contains("rc")) {
                # Skip pre-releases
                continue
            }

            if ($null -ne $repository.imagePrefix) {
                if ($version.StartsWith($repository.imagePrefix)) {
                    $version = $version.Substring($repository.imagePrefix.Length)
                }
            }

            try {
                $versionV = New-Object "System.Management.Automation.SemanticVersion" $version
            }
            catch {
                Write-Host "Skipping $($repository.repository): tag '$version' is not a valid SemVer"
                continue
            }
        }
    }
    elseif ($type -eq "docker") {
        
        $registryUrl = "https://hub.docker.com/v2/repositories"
        if (-not [String]::IsNullOrWhiteSpace($repository.registryUrl)) {
            $registryUrl = $repository.registryUrl
        }

        $registryData = Invoke-RestMethod -Uri "$($registryUrl)/$($repository.repository)/tags/?page_size=100"
        $prefix = if ($null -ne $repository.imagePrefix) { $repository.imagePrefix } else { "" }
        $versionV = $registryData.results.name | Where-Object { $_ -NotLike "*-ci*" -and $_ -NotLike "*latest*" -and $_ -NotLike "*rc*" } | ForEach-Object {
            $t = $_; if ($prefix -and $t.StartsWith($prefix)) { $t = $t.Substring($prefix.Length) }
            try { New-Object "System.Management.Automation.SemanticVersion" $t } catch { $null }
        } | Where-Object { $null -ne $_ } | Sort-Object -descending | Select-Object -First 1
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

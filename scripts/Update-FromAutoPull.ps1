<#
    .SYNOPSIS
        Iterate over the source repositories (sourceRepos) in the base directory (basePath) and process updates for dependencies and automatic updates

    .DESCRIPTION
        The script will iterate over the source repositories and recursively search for chart.yaml files.  It will then search the helm repositories on  
        the local machine to find updates.  If an update is available, the following occurs:
            Chart.yaml is updated with the new version
            Chart.lock is updated by calling helm dependency update

        In addition, if an `auto-update.json` file is present, `Update-HelmFromAutoUpdate.ps1` is run on that folder to update tasgs from external sources.

        This script assumes that the `helm` command is available on your local machine.

    .EXAMPLE
        Update-HelmCharts -basePath c:\ops -sourceRepos @("repository1", "repository2")

    .PARAMETER basePath
        The base path to search for sourceRepos

    .PARAMETER sourceRepos
        An array of folder names within the basePath that correspond to GitOps Git repositories.
#>


param (
    $basePath,
    $sourceRepos = @(),
    $scriptRoot = $PSScriptRoot
)

Push-Location $basePath

Write-Host "Updating Auto-Pull Resources"

foreach ($sourceRepo in $sourceRepos) {

    Write-Host "Processing $sourceRepo"
    
    Push-Location $sourceRepo

    Invoke-Expression "git checkout main"
    Invoke-Expression "git pull"
    
    $baseLocation = Get-Location
    $basePath = $baseLocation.Path

    $autoPullFiles = get-childitem auto-pull.json -Recurse

    foreach ($autoPullFile in $autoPullFiles) {

        $autoPullConfig = Get-Content $autoPullFile.FullName -Raw | ConvertFrom-Json

        foreach ($file in $autoPullConfig.files) {

            Write-Host "Downloading $($file.name)"
            Write-Host "  Source: $($file.url)"
            Write-Host "  Destination: $($file.path)"

            $filePath = Join-Path $autoPullFile.DirectoryName $file.path

            Invoke-WebRequest -Uri $file.url -OutFile $filePath
        }
    }

    $modifiedFiles = Invoke-Expression "git status --porcelain"

    if ($null -ne $modifiedFiles -and $modifiedFiles -ne "") {
        Write-Host "Changes detected"
        $hasChanges = $true
        $commitComment += "Updated auto-pulled resources"
    }
    else {
        Write-Host "No changes detected"
    }

    if ($hasChanges) {
        $commitComment = $commitComment | Sort-Object -Unique
        $commitComment = $commitComment -join "`n"
        Write-Host "Committing changes"
        Invoke-Expression "git add ."
        Invoke-Expression "git commit -m `"$commitComment`""
        Invoke-Expression "git push"
    }
    Pop-Location
}

Pop-Location
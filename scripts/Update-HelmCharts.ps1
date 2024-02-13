<#
    .SYNOPSIS
        Iterate over the source repositories (sourceRepos) in the base directory (basePath) and process updates for dependencies and automatic updates

    .DESCRIPTION
        The script will iterate over the source repositories and recursively search for chart.yaml files.  It will then search the helm repositories on  
        the local machine to find updates.  If an update is available, the following occurs:
            Chart.yaml is updated with the new version
            Chart.lock is updated by calling helm dependency update

        In addition, if an `auto-update.json` file is present, `Update-FromAutoUpdate.ps1` is run on that folder to update tasgs from external sources.

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
    $sourceRepos = @()
)



Push-Location $basePath

Write-Host "Updating Helm Repositories" -NoNewline
Invoke-Expression "helm repo update" | Out-Null
Write-Host " - Done"

$repos = ConvertFrom-Json (Invoke-Expression "helm repo list -o json")


foreach ($sourceRepo in $sourceRepos) {

    Write-Host "Processing $sourceRepo"
    
    Push-Location $sourceRepo

    Invoke-Expression "git checkout main"
    Invoke-Expression "git pull"
    
    $baseLocation = Get-Location
    $basePath = $baseLocation.Path

    $charts = get-childitem chart.yaml -Recurse
    $commitComment = @()
    $hasChanges = $false
    foreach ($chart in $charts) {

        $chartDisplay = $chart.DirectoryName.Replace("$basePath\", "")
        Write-Host "Processing $chartDisplay"
        $yaml = ConvertFrom-Yaml (Get-Content -Raw $chart)
        $updated = $false
        for ($index = 0; $index -lt $yaml.dependencies.Count; $index++) {
            $name = $yaml.dependencies[$index].name
            $version = New-Object "System.Management.Automation.SemanticVersion" $yaml.dependencies[$index].version.replace("v", "")
            $url = $yaml.dependencies[$index].repository
            $repo = $repos | Where-Object {$_.url -eq $url} | Select-Object -First 1
            
            $searchResult = ConvertFrom-Json (Invoke-Expression "helm search repo $($repo.name)/$name -o json")
            $singleResult = $searchResult | Where-Object { $_.name -eq "$($repo.name)/$name"} | Select-Object -First 1

            $newVersion = $singleResult.version
            $repoVersion = New-Object "System.Management.Automation.SemanticVersion" $newVersion.replace("v", "")

            if ($version -lt $repoVersion) {
                Write-Host "Updating $name : $version -> $repoVersion"
                $commitComment += "Bump $name from $version to $repoVersion"
                $yaml.dependencies[$index].version = $newVersion
                $yaml.version = $newVersion
                $updated = $true
            }
            elseif ($version.BuildLabel -ne $repoVersion.BuildLabel) {
                Write-Host "Updating $name : $version -> $repoVersion"
                $commitComment += "Bump $name from $version to $repoVersion"
                $yaml.dependencies[$index].version = $newVersion
                $yaml.version = $newVersion
                $updated = $true
            }
        }

        $githubUpdate = Invoke-Expression "$PSScriptRoot/Update-FromAutoUpdate.ps1 -path $($chart.DirectoryName) -name $chartDisplay"
        if ($githubUpdate.updated) {
            $updated = $true
            $commitComment += $githubUpdate.comment
        }

        if ($updated) {
            (ConvertTo-Yaml $yaml) | Out-String | Set-Content -path $chart.FullName;
            $hasChanges = $true
            Push-Location $chart.DirectoryName
            Write-Host "Updating dependencies" -NoNewline
            Invoke-Expression "helm dependency update" | Out-Null
            Write-Host " - Done"
            Pop-Location
        }
    }

    if ($hasChanges) {
        $commitComment = $commitComment | Sort-Object -Unique
        $commitComment = $commitComment -join "`n"
        Write-Host "Committing changes"
        Invoke-Expression "git add ."
        Invoke-Expression "git commit -m `"$commitComment`""
        Invoke-Expression "git push"
    }
    else {
        Write-Host "No changes detected"
    }
    Pop-Location
}

Pop-Location
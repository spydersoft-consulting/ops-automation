<#
    .SYNOPSIS
        Iterate over the source repositories (sourceRepos) in the base directory (basePath), and add helm repositories to your
        local enviroment that are needed for any charts in the source directory

    .DESCRIPTION
        The script will iterate over the source repositories and recursively search for chart.yaml files.  Any dependencies in the chart.yaml 
        file will be added to the local helm repository list using helm repo add.

        This script assumes that the `helm` command is available on your local machine.

    .EXAMPLE
        Update-HelmRepositoryList -basePath c:\ops -sourceRepos @("repository1", "repository2")

    .PARAMETER basePath
        The base path to search for sourceRepos

    .PARAMETER sourceRepos
        An array of folder names within the basePath that correspond to GitOps Git repositories.
#>

param (
    $basePath,
    $sourceRepos = @()
)

$currentHelmRepos = ConvertFrom-Json (Invoke-Expression "helm repo list -o json")

foreach ($sourceRepo in $sourceRepos) {

    Write-Host "Processing $sourceRepo"
    Push-Location $sourceRepo
    Invoke-Expression "git checkout main"
    Invoke-Expression "git pull"

    $charts = get-childitem chart.yaml -Recurse 

    foreach ($chart in $charts) {
        Write-Host "Processing $chart"
        $yaml = ConvertFrom-Yaml (Get-Content -Raw $chart)
        for ($index = 0; $index -lt $yaml.dependencies.Count; $index++) {
            $url = $yaml.dependencies[$index].repository
            if ($null -eq ($currentHelmRepos | Where-Object { $_.url -eq $url })) {
                $name = $yaml.dependencies[$index].name.Replace("https://", "").Replace(".", "-").Replace("/", "-");
                
                Write-Host "Adding $url with name $name"
                Invoke-Expression "helm repo add $name $url"
                $currentHelmRepos = ConvertFrom-Json (Invoke-Expression "helm repo list -o json")
            }
        }
    }
    Pop-Location
}
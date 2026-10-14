<#
.SYNOPSIS
  Prepares this directory for local tofu runs against one environment.

.DESCRIPTION
  - loads the state-backend credentials from Vault (your Vault CLI must be logged in)
  - builds the provider from a local checkout into terraform.d/plugins (the same
    implied local mirror the pipeline installs the release into)
  - runs "tofu init" with the environment's state key

  Dot-source it so the AWS_* variables stay set for the tofu commands you run next:

    . ./Initialize-Local.ps1 -Environment test
    tofu plan -var-file environments/test.tfvars
#>
param (
    [ValidateSet("test", "production")]
    [string]$Environment = "test",

    # Local checkout of terraform-provider-spydersoft-identity to build.
    [string]$ProviderRepo = "D:\spydersoft\identity\terraform-provider-spydersoft-identity",

    # Must match the version constraint in providers.tf.
    [string]$ProviderVersion = "0.2.0",

    # Skip the provider build (use what is already in terraform.d).
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot

. (Join-Path $here "..\initialize-backend-authentication.ps1")

if (-not $SkipBuild) {
    $os = if ($IsWindows) { "windows" } elseif ($IsMacOS) { "darwin" } else { "linux" }
    $arch = if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq "Arm64") { "arm64" } else { "amd64" }
    $exe = if ($IsWindows) { ".exe" } else { "" }
    $target = Join-Path $here "terraform.d/plugins/registry.opentofu.org/spydersoft-consulting/spydersoft-identity/$ProviderVersion/${os}_${arch}"
    New-Item -ItemType Directory -Force $target | Out-Null

    Push-Location $ProviderRepo
    try {
        go build -o (Join-Path $target "terraform-provider-spydersoft-identity_v$ProviderVersion$exe") .
        if ($LASTEXITCODE -ne 0) { throw "go build failed" }
    }
    finally { Pop-Location }
    Write-Host "Built provider into $target"
}

Push-Location $here
try {
    tofu init -reconfigure "-backend-config=key=identity/$Environment/terraform.tfstate"
    if ($LASTEXITCODE -ne 0) { throw "tofu init failed" }
}
finally { Pop-Location }

Write-Host "Ready. Next: tofu plan -var-file environments/$Environment.tfvars"

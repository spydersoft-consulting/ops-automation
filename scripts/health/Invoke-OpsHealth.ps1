#Requires -Version 7
<#
.SYNOPSIS
  One-shot health sweep of all Kubernetes clusters + the Proxmox cluster.
  Runs every collector in parallel, then prints ONE compact markdown report
  (anomalies only) so an agent/human can review it without further tool calls.

.EXAMPLE
  pwsh scripts/health/Invoke-OpsHealth.ps1
  pwsh scripts/health/Invoke-OpsHealth.ps1 -SkipProxmox -Clusters production
#>
[CmdletBinding()]
param(
    [string[]]$Clusters = @('internal', 'nonproduction', 'production'),   # kubectl context names
    [string[]]$ProxmoxHosts = @('pmxblue.gerega.net', 'pmxblack.gerega.net', 'pxhp.gerega.net'),
    [switch]$SkipKubernetes,
    [switch]$SkipProxmox,
    [switch]$SkipAlerts,       # Mimir ruler/alertmanager alert state
    [string]$MimirUrl = 'https://mimir.mattgerega.net',   # tenants == $Clusters (X-Scope-OrgID)
    [int]$RestartThreshold = 5,
    [int]$EventMinutes = 60,
    [int]$TimeoutSeconds = 240,
    [string]$OutRoot = (Join-Path $PSScriptRoot 'out'),
    [switch]$Quiet     # don't print the report to stdout (just write it)
)

$ErrorActionPreference = 'Stop'
foreach ($tool in 'kubectl', 'ssh') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "$tool not on PATH (winget links vanish - run ~/bin/fix-winget-links.sh)"
    }
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDir = Join-Path $OutRoot $stamp
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

$pwsh = (Get-Process -Id $PID).Path
$jobs = @()
function Start-Collector([string]$Name, [string]$Script, [string[]]$ScriptArgs) {
    $log = Join-Path $runDir "$Name.log"
    $argList = @('-NoProfile', '-File', (Join-Path $PSScriptRoot $Script)) + $ScriptArgs
    $p = Start-Process -FilePath $pwsh -ArgumentList $argList -PassThru -WindowStyle Hidden `
        -RedirectStandardOutput $log -RedirectStandardError "$log.err"
    [pscustomobject]@{ Name = $Name; Proc = $p; Report = Join-Path $runDir "$Name.md"; Log = $log }
}

if (-not $SkipKubernetes) {
    foreach ($c in $Clusters) {
        $jobs += Start-Collector "k8s-$c" 'k8s-health.ps1' @(
            '-Context', $c, '-OutFile', (Join-Path $runDir "k8s-$c.md"),
            '-RestartThreshold', $RestartThreshold, '-EventMinutes', $EventMinutes)
    }
}
if (-not $SkipAlerts) {
    $jobs += Start-Collector 'alerts' 'alerts-health.ps1' @(
        '-OutFile', (Join-Path $runDir 'alerts.md'), '-BaseUrl', $MimirUrl, '-Tenants', ($Clusters -join ','))
}
if (-not $SkipProxmox) {
    $jobs += Start-Collector "proxmox" 'proxmox-health.ps1' @(
        '-Hosts', ($ProxmoxHosts -join ','), '-OutFile', (Join-Path $runDir 'proxmox.md'))
}

# wait, killing stragglers
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
foreach ($j in $jobs) {
    $left = [Math]::Max(1, [int]($deadline - (Get-Date)).TotalSeconds)
    if (-not $j.Proc.WaitForExit($left * 1000)) { $j.Proc.Kill($true); $j | Add-Member Timeout $true }
}

# assemble
$sections = foreach ($j in $jobs) {
    if (Test-Path $j.Report) { Get-Content -Raw $j.Report }
    else {
        $err = (Get-Content -Raw "$($j.Log).err" -ErrorAction SilentlyContinue)
        "## $($j.Name)`n`n- [CRIT] collector $(if ($j.Timeout) { "timed out after ${TimeoutSeconds}s" } else { 'failed' }) and produced no report. $($err -replace '\s+',' ')`n"
    }
}
$all = $sections -join "`n"
$nCrit = ([regex]::Matches($all, '(?m)^- \[CRIT\]')).Count
$nWarn = ([regex]::Matches($all, '(?m)^- \[WARN\]')).Count

$header = @"
# Ops health report - $(Get-Date -Format 'yyyy-MM-dd HH:mm zzz')

**Totals: $nCrit CRIT, $nWarn WARN.** Findings are anomalies only; "Clean:" lists checks that found nothing.
Severity: CRIT = broken/unavailable now, WARN = degraded or will bite soon, INFO = context.

"@
$report = $header + $all
$reportPath = Join-Path $runDir 'report.md'
Set-Content -Path $reportPath -Value $report -Encoding utf8
Copy-Item $reportPath (Join-Path $OutRoot 'latest.md') -Force

if (-not $Quiet) { $report }
Write-Host "`n(report saved: $reportPath)" -ForegroundColor DarkGray

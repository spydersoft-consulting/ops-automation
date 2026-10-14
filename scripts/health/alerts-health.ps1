#Requires -Version 7
<#
.SYNOPSIS
  Pulls alert state from Mimir (ruler + alertmanager) for each tenant and writes a compact
  markdown report: firing alerts, pending alerts (INFO), Alertmanager active/silenced counts,
  and rules that fail to evaluate.
#>
[CmdletBinding()]
param(
    [string]$BaseUrl = 'https://mimir.mattgerega.net',
    [string[]]$Tenants = @('internal', 'nonproduction', 'production'),
    [string]$GrafanaUrl = 'https://grafana.mattgerega.net',   # '' to skip Grafana-managed rules
    [string]$SecretContext = 'internal',                      # kube context holding the Grafana admin secret
    [string]$SecretNamespace = 'monitoring',
    [string]$SecretName = 'grafana-admin-secret',
    [Parameter(Mandatory)][string]$OutFile,
    [int]$MaxPerTenant = 25
)

$ErrorActionPreference = 'Continue'
$Tenants = @($Tenants | ForEach-Object { $_ -split ',' } | Where-Object { $_ })   # -File passes arrays as one comma string
$lines = [System.Collections.Generic.List[string]]::new()
$clean = [System.Collections.Generic.List[string]]::new()

function Get-Mimir([string]$Tenant, [string]$Path) {
    try { Invoke-RestMethod -Uri "$BaseUrl/$Path" -Headers @{ 'X-Scope-OrgID' = $Tenant } -TimeoutSec 30 -SkipCertificateCheck }
    catch { $script:lastErr = $_.Exception.Message; $null }
}
function Short([string]$s, [int]$n = 160) { $s = $s -replace '\s+', ' '; if ($s.Length -gt $n) { $s.Substring(0, $n) + '...' } else { $s } }

foreach ($t in $Tenants) {
    $found = 0
    $a = Get-Mimir $t 'prometheus/api/v1/alerts'
    if (-not $a) { $lines.Add("- [CRIT] ${t}: cannot query ruler alerts at $BaseUrl ($lastErr)"); continue }

    $alerts = @($a.data.alerts)
    $firing = @($alerts | Where-Object state -eq 'firing')
    $pending = @($alerts | Where-Object state -eq 'pending')
    # one line per alertname+severity, with instance count and a sample
    foreach ($g in ($firing | Group-Object { "$($_.labels.alertname)|$($_.labels.severity)" } | Select-Object -First $MaxPerTenant)) {
        $f = $g.Group[0]; $sev = if ($f.labels.severity -eq 'critical') { 'CRIT' } else { 'WARN' }
        $where = ($g.Group | ForEach-Object { $_.labels.instance ?? $_.labels.pod ?? $_.labels.node ?? $_.labels.namespace } | Where-Object { $_ } | Select-Object -Unique -First 3) -join ','
        $lines.Add("- [$sev] alert/${t}: FIRING $($f.labels.alertname) x$($g.Count) [$where] $(Short ($f.annotations.summary ?? $f.annotations.description)) (since $(([datetime]$f.activeAt).ToUniversalTime().ToString('MM-dd HH:mm'))Z)")
        $found++
    }
    foreach ($g in ($pending | Group-Object { $_.labels.alertname } | Select-Object -First 10)) {
        $lines.Add("- [INFO] alert/${t}: pending $($g.Name) x$($g.Count) $(Short ($g.Group[0].annotations.summary ?? $g.Group[0].annotations.description) 100)")
    }

    # Alertmanager (anything already routed/active, silences)
    $am = Get-Mimir $t 'alertmanager/api/v2/alerts?active=true&silenced=false&inhibited=false'
    foreach ($x in @($am) | Where-Object { $_ } | Group-Object { $_.labels.alertname } | Select-Object -First 10) {
        if (-not ($firing | Where-Object { $_.labels.alertname -eq $x.Name })) {
            $lines.Add("- [WARN] alertmanager/${t}: active $($x.Name) x$($x.Count) (not in ruler firing list - likely external/Grafana-managed)"); $found++
        }
    }

    # Rules that fail to evaluate (silent alerting outage)
    $r = Get-Mimir $t 'prometheus/api/v1/rules'
    if ($r) {
        $rules = @($r.data.groups | ForEach-Object { $grp = $_; $_.rules | ForEach-Object { [pscustomobject]@{ G = $grp.name; N = $_.name; H = $_.health; E = $_.lastError } } })
        $bad = @($rules | Where-Object { $_.H -and $_.H -ne 'ok' })
        foreach ($b in ($bad | Select-Object -First 10)) { $lines.Add("- [WARN] rules/${t}: $($b.G)/$($b.N) health=$($b.H) $(Short $b.E 200)"); $found++ }
        if ($bad.Count -gt 10) { $lines.Add("- [WARN] rules/${t}: ...and $($bad.Count - 10) more failing rules") }
        $lines.Add("- [INFO] rules/${t}: $($rules.Count) rules loaded, $($bad.Count) unhealthy")
    }
    else { $lines.Add("- [WARN] rules/${t}: could not query rules ($lastErr)"); $found++ }

    if ($found -eq 0) { $clean.Add($t) }
}

# ---- Grafana-managed alert rules (not visible via the Mimir ruler) --------------------
# Credentials are read from the cluster secret at runtime and kept in memory only.
if ($GrafanaUrl) {
    try {
        $sec = (& kubectl --context $SecretContext -n $SecretNamespace get secret $SecretName -o json 2>$null) -join '' | ConvertFrom-Json
        if (-not $sec.data) { throw "secret $SecretNamespace/$SecretName not readable via context '$SecretContext'" }
        $dec = { param($k) [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($sec.data.$k)) }
        $cred = [pscustomobject]@{ U = & $dec 'GRAFANA_ADMIN_USER'; P = & $dec 'GRAFANA_ADMIN_PASSWORD' }
        $auth = @{ Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($cred.U):$($cred.P)")) }
        $gr = Invoke-RestMethod -Uri "$GrafanaUrl/api/prometheus/grafana/api/v1/rules" -Headers $auth -TimeoutSec 30 -SkipCertificateCheck
        $rules = @($gr.data.groups | ForEach-Object { $folder = $_.file; $_.rules | ForEach-Object { $_ | Add-Member Folder $folder -PassThru } })
        $bad = 0
        foreach ($g in ($rules | Where-Object { $_.state -in 'firing', 'pending', 'recovering' } | Group-Object name)) {
            $r = $g.Group[0]; $isFiring = $r.state -eq 'firing'
            $sev = if (-not $isFiring) { 'INFO' } elseif ($r.labels.severity -eq 'critical') { 'CRIT' } else { 'WARN' }
            $inst = @($r.alerts | Where-Object { $_.state -in 'Alerting', 'Normal (Alerting)', 'Pending' -or $_.state -match 'Alerting|Pending' })
            $where = ($inst | ForEach-Object { $l = $_.labels; $l.pod ?? $l.instance ?? $l.node ?? $l.namespace } | Where-Object { $_ } | Select-Object -Unique -First 4) -join ','
            $lines.Add("- [$sev] grafana-alert: $($r.state.ToUpper()) $($r.name) [$($r.Folder)] x$($inst.Count) [$where] $(Short ($r.annotations.summary ?? $r.annotations.description) 140)")
            $bad++
        }
        foreach ($r in ($rules | Where-Object { $_.health -and $_.health -ne 'ok' } | Select-Object -First 10)) {
            $lines.Add("- [WARN] grafana-alert: rule '$($r.name)' [$($r.Folder)] health=$($r.health) $(Short $r.lastError 200)"); $bad++
        }
        $lines.Add("- [INFO] grafana-alert: $($rules.Count) Grafana-managed rules, $bad firing/pending/unhealthy")
        if ($bad -eq 0) { $clean.Add('grafana-managed') }
    }
    catch { $lines.Add("- [WARN] grafana-alert: could not query Grafana-managed rules: $(Short $_.Exception.Message 200)") }
}

$out = @("## Alerts (Mimir @ $BaseUrl)", '', "Tenants: $($Tenants -join ', ')", '') + $lines
if ($clean) { $out += "- Clean (no firing alerts, rules healthy): $($clean -join ', ')" }
Set-Content -Path $OutFile -Value ($out -join "`n") -Encoding utf8

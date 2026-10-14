#Requires -Version 7
<#
.SYNOPSIS
  Collects Proxmox cluster + per-host health over SSH (read-only) and writes a compact
  markdown report containing only anomalies.
  Cluster-level data (quorum, guests, storage, failed tasks) comes from one pvesh call on the
  first reachable host; per-host checks run proxmox-host-check.sh on every host in parallel.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Hosts,
    [Parameter(Mandatory)][string]$OutFile,
    [string]$SshUser = 'root',
    [int]$TaskLookbackHours = 24
)

$ErrorActionPreference = 'Continue'
$Hosts = @($Hosts | ForEach-Object { $_ -split ',' } | Where-Object { $_ })   # -File passes arrays as one comma string
$remote = (Get-Content -Raw (Join-Path $PSScriptRoot 'proxmox-host-check.sh')) -replace "`r", ''
$sshOpts = @('-o', 'BatchMode=yes', '-o', 'ConnectTimeout=8', '-o', 'ServerAliveInterval=5')
$findings = [System.Collections.Generic.List[string]]::new()
function Add-Finding([string]$Sev, [string]$Where, [string]$Text) { $findings.Add("- [$Sev] ${Where}: $Text") }

# ---- per-host checks, in parallel ------------------------------------------------
$results = $Hosts | ForEach-Object -Parallel {
    $out = $using:remote | & ssh @($using:sshOpts) "$($using:SshUser)@$_" 'bash -s' 2>&1
    [pscustomobject]@{ Host = $_; Exit = $LASTEXITCODE; Output = @($out) }
} -ThrottleLimit 8

$reachable = @()
foreach ($r in $results) {
    $short = ($r.Host -split '\.')[0]
    $tagged = @($r.Output | Where-Object { "$_" -match '^\[(CRIT|WARN|INFO)\] ' })
    if ($r.Exit -ne 0 -and -not $tagged) {
        Add-Finding CRIT $short "unreachable over SSH: $((($r.Output | Out-String).Trim()) -replace '\s+',' ')"
        continue
    }
    $reachable += $r.Host
    foreach ($l in $tagged) { $m = [regex]::Match("$l", '^\[(\w+)\] (.*)$'); Add-Finding $m.Groups[1].Value $short $m.Groups[2].Value }
}

# ---- cluster-level data via pvesh on the first reachable host ----------------------
$inv = "Hosts checked: $($Hosts.Count), reachable: $($reachable.Count)"
if ($reachable.Count -eq 0) {
    Add-Finding CRIT 'cluster' 'no host reachable - skipping cluster checks'
}
else {
    $q = 'echo "###STATUS"; pvesh get /cluster/status --output-format json; ' +
    'echo "###RESOURCES"; pvesh get /cluster/resources --output-format json; ' +
    'echo "###TASKS"; pvesh get /cluster/tasks --output-format json'
    $raw = (& ssh @sshOpts "$SshUser@$($reachable[0])" $q 2>$null) -join "`n"
    $parts = @{}
    foreach ($s in ($raw -split '###' | Where-Object { $_.Trim() })) {
        $name, $body = $s -split "`n", 2
        try { $parts[$name.Trim()] = $body | ConvertFrom-Json -Depth 50 } catch { }
    }

    if ($parts.STATUS) {
        $cl = $parts.STATUS | Where-Object type -eq 'cluster'
        if ($cl -and $cl.quorate -ne 1) { Add-Finding CRIT 'cluster' "'$($cl.name)' has NO QUORUM" }
        foreach ($n in ($parts.STATUS | Where-Object type -eq 'node')) {
            if ($n.online -ne 1) { Add-Finding CRIT 'cluster' "node $($n.name) offline" }
        }
        $inv += " | cluster '$($cl.name)' nodes=$(@($parts.STATUS | Where-Object type -eq 'node').Count) quorate=$($cl.quorate)"
    }
    else { Add-Finding WARN 'cluster' 'could not read /cluster/status' }

    if ($parts.RESOURCES) {
        $res = @($parts.RESOURCES)
        foreach ($n in ($res | Where-Object type -eq 'node')) {
            if ($n.status -ne 'online') { Add-Finding CRIT $n.node "node status '$($n.status)'" }
            elseif ($n.maxmem -gt 0 -and ($n.mem / $n.maxmem) -ge 0.9) {
                Add-Finding WARN $n.node ("host memory {0:P0} used" -f ($n.mem / $n.maxmem))
            }
        }
        foreach ($s in ($res | Where-Object type -eq 'storage')) {
            if ($s.status -ne 'available') { Add-Finding CRIT $s.node "storage $($s.storage) status '$($s.status)'"; continue }
            if ($s.maxdisk -gt 0) {
                $pct = $s.disk / $s.maxdisk
                if ($pct -ge 0.92) { Add-Finding CRIT $s.node ("storage {0} {1:P0} full" -f $s.storage, $pct) }
                elseif ($pct -ge 0.85) { Add-Finding WARN $s.node ("storage {0} {1:P0} full" -f $s.storage, $pct) }
            }
        }
        $guests = @($res | Where-Object { $_.type -in 'qemu', 'lxc' -and -not $_.template })
        $running = @($guests | Where-Object status -eq 'running')
        $stopped = @($guests | Where-Object status -ne 'running')
        $inv += " | guests running=$($running.Count) stopped=$($stopped.Count)"
        if ($stopped) {
            Add-Finding INFO 'cluster' ("stopped guests: " + (($stopped | Sort-Object node, vmid | ForEach-Object { "$($_.name)($($_.vmid)@$($_.node))" }) -join ', '))
        }
        foreach ($g in $running) {
            if ($g.maxmem -gt 0 -and ($g.mem / $g.maxmem) -ge 0.95) {
                Add-Finding WARN $g.node ("guest {0}({1}) memory {2:P0}" -f $g.name, $g.vmid, ($g.mem / $g.maxmem))
            }
        }
    }
    else { Add-Finding WARN 'cluster' 'could not read /cluster/resources' }

    if ($parts.TASKS) {
        $cut = [DateTimeOffset]::UtcNow.AddHours(-$TaskLookbackHours).ToUnixTimeSeconds()
        $bad = @($parts.TASKS | Where-Object { $_.starttime -ge $cut -and $_.status -and $_.status -ne 'OK' })
        foreach ($g in ($bad | Group-Object { "$($_.type)|$($_.id)|$($_.status)" } | Sort-Object Count -Descending | Select-Object -First 20)) {
            $f = $g.Group[0]
            $when = [DateTimeOffset]::FromUnixTimeSeconds($g.Group[-1].starttime).UtcDateTime.ToString('MM-dd HH:mm')
            Add-Finding WARN $f.node "task $($f.type) $($f.id) '$($f.status)' x$($g.Count) (latest $when Z)"
        }
    }
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("## Proxmox")
[void]$sb.AppendLine("")
[void]$sb.AppendLine($inv)
[void]$sb.AppendLine("")
foreach ($sev in 'CRIT', 'WARN', 'INFO') { foreach ($l in ($findings | Where-Object { $_.StartsWith("- [$sev]") })) { [void]$sb.AppendLine($l) } }
if (-not ($findings | Where-Object { -not $_.StartsWith("- [INFO]") })) { [void]$sb.AppendLine('- No CRIT/WARN findings on any host.') }
Set-Content -Path $OutFile -Value $sb.ToString() -Encoding utf8

#Requires -Version 7
<#
.SYNOPSIS
  Collects Kubernetes health for ONE cluster context and writes a compact markdown
  report containing only anomalies (plus a one-line inventory).
  Normally invoked by Invoke-OpsHealth.ps1, but can be run standalone.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Context,
    [Parameter(Mandatory)][string]$OutFile,
    [int]$RestartThreshold = 5,   # restarts (with a termination in last 24h) before a pod is flagged
    [int]$EventMinutes = 60,      # warning-event lookback window
    [int]$MaxPerArea = 25         # cap lines per area in the report
)

$ErrorActionPreference = 'Continue'
$now = [DateTime]::UtcNow
$findings = [System.Collections.Generic.List[object]]::new()
$ran = [System.Collections.Generic.List[string]]::new()

function Add-Finding([string]$Sev, [string]$Area, [string]$Text) {
    $findings.Add([pscustomobject]@{ Sev = $Sev; Area = $Area; Text = $Text })
}
function ToUtc($v) { if ($v) { ([datetime]$v).ToUniversalTime() } }
function Get-KubeJson([string[]]$KArgs) {
    $raw = & kubectl --context $Context --request-timeout=60s @KArgs -o json 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $raw) { return $null }
    ($raw -join "`n") | ConvertFrom-Json -AsHashtable -Depth 100
}
function Write-Report([string]$Inventory) {
    $crit = @($findings | Where-Object Sev -eq 'CRIT')
    $warn = @($findings | Where-Object Sev -eq 'WARN')
    $info = @($findings | Where-Object Sev -eq 'INFO')
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("## Kubernetes: $Context")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("$Inventory")
    [void]$sb.AppendLine("")
    foreach ($grp in @(@('CRIT', $crit), @('WARN', $warn), @('INFO', $info))) {
        foreach ($byArea in ($grp[1] | Group-Object Area)) {
            $items = @($byArea.Group)
            foreach ($f in ($items | Select-Object -First $MaxPerArea)) {
                [void]$sb.AppendLine("- [$($grp[0])] $($f.Area): $($f.Text)")
            }
            if ($items.Count -gt $MaxPerArea) {
                [void]$sb.AppendLine("- [$($grp[0])] $($byArea.Name): ...and $($items.Count - $MaxPerArea) more (full list: re-run k8s-health.ps1 with -MaxPerArea)")
            }
        }
    }
    $dirty = @($findings | Where-Object { $_.Sev -ne 'INFO' } | ForEach-Object Area | Select-Object -Unique)
    $clean = @($ran | Where-Object { $_ -notin $dirty })
    if ($clean) { [void]$sb.AppendLine("- Clean: $($clean -join ', ')") }
    Set-Content -Path $OutFile -Value $sb.ToString() -Encoding utf8
}

# ---- 0. API reachability ----------------------------------------------------
$ready = & kubectl --context $Context --request-timeout=15s get --raw '/readyz' 2>&1
if ($LASTEXITCODE -ne 0) {
    Add-Finding CRIT 'api' "API server unreachable or not ready: $(($ready | Out-String).Trim() -replace '\s+',' ')"
    Write-Report '_cluster unreachable - no further checks_'
    return
}

# ---- 1. Nodes ----------------------------------------------------------------
$ran.Add('nodes')
$nodes = Get-KubeJson @('get', 'nodes')
$versions = @{}
foreach ($n in $nodes.items) {
    $name = $n.metadata.name
    $versions[$n.status.nodeInfo.kubeletVersion] = 1 + ($versions[$n.status.nodeInfo.kubeletVersion] ?? 0)
    foreach ($c in $n.status.conditions) {
        if ($c.type -eq 'Ready' -and $c.status -ne 'True') {
            Add-Finding CRIT 'nodes' "$name NotReady ($($c.status)): $($c.reason) - $($c.message)"
        }
        elseif ($c.type -in 'MemoryPressure', 'DiskPressure', 'PIDPressure', 'NetworkUnavailable' -and $c.status -eq 'True') {
            Add-Finding WARN 'nodes' "$name $($c.type)"
        }
    }
    if ($n.spec.unschedulable) { Add-Finding WARN 'nodes' "$name cordoned (SchedulingDisabled)" }
    foreach ($t in @($n.spec.taints)) {
        if ($t -and $t.effect -in 'NoSchedule', 'NoExecute' -and $t.key -notmatch 'control-plane|master|etcd|CriticalAddonsOnly|node.kubernetes.io/unschedulable') {
            Add-Finding WARN 'nodes' "$name taint $($t.key)=$($t.value):$($t.effect)"
        }
    }
}
if ($versions.Count -gt 1) {
    Add-Finding WARN 'nodes' "kubelet version skew: $(($versions.GetEnumerator() | ForEach-Object { "$($_.Key) x$($_.Value)" }) -join ', ')"
}

# node CPU/memory (needs metrics-server)
$ran.Add('node-usage')
$top = & kubectl --context $Context --request-timeout=30s top nodes --no-headers 2>$null
if ($LASTEXITCODE -eq 0) {
    foreach ($line in $top) {
        $f = ($line.Trim() -split '\s+')
        if ($f.Count -ge 5) {
            $cpu = [int]($f[2].TrimEnd('%')); $mem = [int]($f[4].TrimEnd('%'))
            if ($cpu -ge 85 -or $mem -ge 85) { Add-Finding WARN 'node-usage' "$($f[0]) cpu=$cpu% mem=$mem%" }
        }
    }
}

# ---- 2. Pods -----------------------------------------------------------------
$ran.Add('pods')
$pods = Get-KubeJson @('get', 'pods', '-A')
$badWaiting = 'CrashLoopBackOff', 'ImagePullBackOff', 'ErrImagePull', 'CreateContainerError', 'CreateContainerConfigError', 'InvalidImageName'
$failedPods = @{}
foreach ($p in $pods.items) {
    $ns =$p.metadata.namespace; $id = "$ns/$($p.metadata.name)"; $phase = $p.status.phase
    if ($p.metadata.deletionTimestamp) {
        $age = ($now - (ToUtc $p.metadata.deletionTimestamp)).TotalMinutes
        if ($age -gt 10) { Add-Finding WARN 'pods' "$id stuck Terminating $([int]$age)m (node $($p.spec.nodeName))" }
        continue
    }
    if ($phase -eq 'Succeeded') { continue }
    if ($phase -eq 'Failed') {
        $k = [string]$p.status.reason; if (-not $failedPods.ContainsKey($k)) { $failedPods[$k] = @{ msg = $p.status.message; ids = @() } }
        $failedPods[$k].ids += $id; continue
    }
    $flagged = $false
    foreach ($cs in (@($p.status.containerStatuses) + @($p.status.initContainerStatuses))) {
        if (-not $cs) { continue }
        $w = $cs.state.waiting
        if ($w -and $w.reason -in $badWaiting) {
            Add-Finding CRIT 'pods' "$id/$($cs.name) $($w.reason) restarts=$($cs.restartCount) node=$($p.spec.nodeName)"
            $flagged = $true
        }
        elseif ($cs.restartCount -ge $RestartThreshold -and $cs.lastState.terminated -and
            ($now - (ToUtc $cs.lastState.terminated.finishedAt)).TotalHours -lt 24) {
            $t = $cs.lastState.terminated
            Add-Finding WARN 'pods' "$id/$($cs.name) restarts=$($cs.restartCount) last=$($t.reason)/exit$($t.exitCode) at $((ToUtc $t.finishedAt).ToString('MM-dd HH:mm'))Z"
            $flagged = $true
        }
    }
    if ($flagged) { continue }
    $ownerKind = $p.metadata.ownerReferences[0].kind
    if ($phase -eq 'Pending') {
        $age = ($now - (ToUtc $p.metadata.creationTimestamp)).TotalMinutes
        if ($age -gt 10) {
            $why = ($p.status.conditions | Where-Object { $_.status -eq 'False' } | Select-Object -First 1).message
            Add-Finding WARN 'pods' "$id Pending $([int]$age)m: $why"
        }
    }
    elseif ($phase -eq 'Running' -and $ownerKind -ne 'Job') {
        $rc = $p.status.conditions | Where-Object type -eq 'Ready'
        if ($rc -and $rc.status -ne 'True') {
            $age = ($now - (ToUtc $rc.lastTransitionTime)).TotalMinutes
            if ($age -gt 5) { Add-Finding WARN 'pods' "$id Running but not Ready for $([int]$age)m (node $($p.spec.nodeName))" }
        }
    }
}

foreach ($k in $failedPods.Keys) {   # terminal-phase pods (Evicted/OutOfcpu/...) collapsed per reason
    $f = $failedPods[$k]; $m = ([string]$f.msg -replace '\s+', ' '); if ($m.Length -gt 120) { $m = $m.Substring(0, 120) + '...' }
    Add-Finding WARN 'pods' "$($f.ids.Count) pods Failed '$k' ($m): $(($f.ids | Select-Object -First 8) -join ', ')$(if ($f.ids.Count -gt 8) { ', ...' })"
}

# ---- 3. Workloads ------------------------------------------------------------
$ran.Add('workloads')
$wl = Get-KubeJson @('get', 'deploy,sts,ds', '-A')
foreach ($w in $wl.items) {
    $kind = $w.kind; $id = "$kind $($w.metadata.namespace)/$($w.metadata.name)"
    if ($kind -eq 'DaemonSet') { $want = $w.status.desiredNumberScheduled ?? 0; $have = $w.status.numberReady ?? 0 }
    else { $want = $w.spec.replicas ?? 1; $have = $w.status.readyReplicas ?? 0 }
    if ($want -gt 0 -and $have -lt $want) {
        Add-Finding ($have -eq 0 ? 'CRIT' : 'WARN') 'workloads' "$id ready $have/$want"
    }
}

# ---- 4. Jobs, PVCs, PDBs -------------------------------------------------------
$ran.Add('jobs')
$jobs = Get-KubeJson @('get', 'jobs', '-A')
foreach ($j in $jobs.items) {
    if (($j.status.failed ?? 0) -gt 0 -and -not $j.status.succeeded -and -not $j.status.active) {
        Add-Finding WARN 'jobs' "$($j.metadata.namespace)/$($j.metadata.name) failed x$($j.status.failed)"
    }
}
$ran.Add('pvcs')
$pvcs = Get-KubeJson @('get', 'pvc', '-A')
foreach ($c in $pvcs.items) {
    if ($c.status.phase -ne 'Bound') { Add-Finding WARN 'pvcs' "$($c.metadata.namespace)/$($c.metadata.name) $($c.status.phase)" }
}
$ran.Add('pdbs')
$pdbs = Get-KubeJson @('get', 'pdb', '-A')
foreach ($d in $pdbs.items) {
    if ($d.status.disruptionsAllowed -eq 0) {
        Add-Finding WARN 'pdbs' "$($d.metadata.namespace)/$($d.metadata.name) allows 0 disruptions (healthy $($d.status.currentHealthy)/desired $($d.status.desiredHealthy), expected $($d.status.expectedPods)) - blocks node drains"
    }
}

# ---- 5. CRD-backed health (only if installed) ------------------------------------
$apis = @(& kubectl --context $Context api-resources -o name 2>$null)

function Test-ReadyCondition($list, [string]$area, [string]$kind) {
    foreach ($i in $list.items) {
        $rc = @($i.status.conditions) | Where-Object { $_.type -eq 'Ready' }
        if (-not $rc -or $rc.status -ne 'True') {
            Add-Finding WARN $area "$kind $($i.metadata.namespace)/$($i.metadata.name): $($rc.reason) $($rc.message)"
        }
    }
}
if ($apis -contains 'certificates.cert-manager.io') {
    $ran.Add('certificates')
    Test-ReadyCondition (Get-KubeJson @('get', 'certificates.cert-manager.io', '-A')) 'certificates' 'Certificate'
}
if ($apis -contains 'externalsecrets.external-secrets.io') {
    $ran.Add('externalsecrets')
    Test-ReadyCondition (Get-KubeJson @('get', 'externalsecrets.external-secrets.io', '-A')) 'externalsecrets' 'ExternalSecret'
}
if ($apis -contains 'applications.argoproj.io') {
    $ran.Add('argocd-apps')
    $apps = Get-KubeJson @('get', 'applications.argoproj.io', '-A')
    foreach ($a in $apps.items) {
        $id = "$($a.metadata.namespace)/$($a.metadata.name)"
        $sync = $a.status.sync.status; $health = $a.status.health.status
        $errs = @($a.status.conditions | Where-Object { $_.type -match 'Error' })
        if ($errs) { Add-Finding CRIT 'argocd-apps' "$id $($errs[0].type): $(([string]$errs[0].message).Substring(0, [Math]::Min(200, ([string]$errs[0].message).Length)))" }
        elseif ($health -in 'Degraded', 'Missing') { Add-Finding CRIT 'argocd-apps' "$id health=$health sync=$sync" }
        elseif ($sync -ne 'Synced' -or $health -notin 'Healthy', 'Suspended') { Add-Finding WARN 'argocd-apps' "$id sync=$sync health=$health" }
        if ($a.status.operationState.phase -in 'Failed', 'Error') {
            Add-Finding WARN 'argocd-apps' "$id last operation $($a.status.operationState.phase): $($a.status.operationState.message)"
        }
    }
}

# ---- 6. Warning events (digest) ------------------------------------------------
$evs = Get-KubeJson @('get', 'events', '-A', '--field-selector', 'type=Warning')
$cut = $now.AddMinutes(-$EventMinutes)
$groups = @{}
foreach ($e in $evs.items) {
    $ts = ToUtc ($e.lastTimestamp ?? $e.series.lastObservedTime ?? $e.eventTime ?? $e.metadata.creationTimestamp)
    if (-not $ts -or $ts -lt $cut) { continue }
    $key = "$($e.involvedObject.namespace)|$($e.involvedObject.kind)|$($e.reason)"
    if (-not $groups.ContainsKey($key)) { $groups[$key] = @{ n = 0; objs = @{}; msg = $e.message } }
    $groups[$key].n += ($e.count ?? 1)
    $groups[$key].objs[$e.involvedObject.name] = 1
}
$ranEv = $groups.GetEnumerator() | Sort-Object { $_.Value.n } -Descending | Select-Object -First $MaxPerArea
foreach ($g in $ranEv) {
    $ns, $kind, $reason = $g.Key -split '\|'
    $msg = ([string]$g.Value.msg -replace '\s+', ' '); if ($msg.Length -gt 160) { $msg = $msg.Substring(0, 160) + '...' }
    $sample = ($g.Value.objs.Keys | Select-Object -First 2) -join ','
    Add-Finding INFO "events(${EventMinutes}m)" "$ns $kind $reason x$($g.Value.n) objs=$($g.Value.objs.Count) [$sample] $msg"
}

$inv = "Nodes: $(@($nodes.items).Count) ($(($versions.GetEnumerator() | ForEach-Object { "$($_.Key) x$($_.Value)" }) -join ', ')) | Pods: $(@($pods.items).Count) | CRIT: $(@($findings | Where-Object Sev -eq 'CRIT').Count) WARN: $(@($findings | Where-Object Sev -eq 'WARN').Count)"
Write-Report $inv

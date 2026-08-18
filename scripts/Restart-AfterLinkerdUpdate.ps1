<#
    .SYNOPSIS
        Roll meshed workloads after a Linkerd control-plane upgrade so they pick up the new proxy image.

    .DESCRIPTION
        After a Linkerd control-plane upgrade, existing pods keep running the OLD proxy image
        until they restart for some other reason. This script finds every meshed pod whose
        `linkerd-proxy` container image does not match the desired image, groups them by their
        Argo app (the `app.kubernetes.io/instance` label, with namespace as a fallback for pods
        that don't carry that label), and rolls each app one at a time. Within an app, workloads
        are restarted one at a time and each waited to Ready before the next begins -- this
        avoids both thundering-herd container-start pressure on small clusters and ordering
        problems between sibling workloads (e.g. an API coming up against a not-yet-Ready DB).

        The "desired" proxy image is read from the spec of the `linkerd-proxy-injector` Deployment
        in the `linkerd` namespace -- this is the source of truth that the injector itself uses
        when admitting new pods. Apps where every meshed pod already runs that image are skipped,
        so the script is safe to re-run.

        Linkerd's own system namespaces (`linkerd`, `linkerd-viz`, `linkerd-multicluster`) are
        always skipped -- those update via their Argo apps and restarting them from here can
        re-trigger the proxy-injector chicken-and-egg problem during an upgrade.

    .EXAMPLE
        ./Restart-AfterLinkerdUpdate.ps1 -Context nonproduction -DryRun

    .EXAMPLE
        ./Restart-AfterLinkerdUpdate.ps1 -Context nonproduction

    .EXAMPLE
        ./Restart-AfterLinkerdUpdate.ps1 -Context production -ConfirmProduction

    .PARAMETER Context
        kubectl context name. Required so this can't run against the wrong cluster by accident.

    .PARAMETER DryRun
        Print the plan and exit. No restarts are issued.

    .PARAMETER IncludeApps
        If supplied, only these app-instance values are considered.

    .PARAMETER ExcludeApps
        App-instance values to skip.

    .PARAMETER ExcludeNamespaces
        Additional namespaces to skip beyond the Linkerd system namespaces.

    .PARAMETER AppLabel
        Label key used to group workloads into "apps". Defaults to `app.kubernetes.io/instance`,
        which is Argo CD's default tracking label.

    .PARAMETER RolloutTimeoutSeconds
        Per-workload wait timeout passed to `kubectl rollout status`. Default 300.

    .PARAMETER ConfirmProduction
        Required to run against a context whose name matches "prod".
#>

param (
    [Parameter(Mandatory)]
    [string] $Context,
    [switch] $DryRun,
    [string[]] $IncludeApps = @(),
    [string[]] $ExcludeApps = @(),
    [string[]] $ExcludeNamespaces = @(),
    [string] $AppLabel = "app.kubernetes.io/instance",
    [int] $RolloutTimeoutSeconds = 300,
    [switch] $ConfirmProduction
)

$ErrorActionPreference = "Stop"

$systemNs = @("linkerd", "linkerd-viz", "linkerd-multicluster")

if ($Context -match "(?<!non[-_]?)prod" -and -not $ConfirmProduction) {
    Write-Host "Context '$Context' looks like production. Re-run with -ConfirmProduction to proceed." -ForegroundColor Yellow
    exit 2
}

Write-Host "Checking context '$Context'..." -NoNewline
$null = & kubectl --context=$Context get ns linkerd -o name 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host " unreachable or 'linkerd' namespace missing" -ForegroundColor Red
    exit 1
}
Write-Host " ok"

# Read the target proxy image from a *running* proxy-injector pod, since the linkerd-proxy
# sidecar isn't part of the Deployment spec -- it's added by the injector at admission.
# Recent Linkerd releases place the sidecar in spec.initContainers (native Kubernetes sidecars
# with restartPolicy=Always); older ones used spec.containers. Check both.
$injectorJson = & kubectl --context=$Context -n linkerd get pod `
    -l linkerd.io/control-plane-component=proxy-injector -o json
$injector = $injectorJson | ConvertFrom-Json
if (-not $injector.items -or $injector.items.Count -eq 0) {
    Write-Host "No proxy-injector pod found." -ForegroundColor Red
    exit 1
}
$injectorContainers = @()
if ($injector.items[0].spec.initContainers) { $injectorContainers += $injector.items[0].spec.initContainers }
if ($injector.items[0].spec.containers)     { $injectorContainers += $injector.items[0].spec.containers }
$proxy = $injectorContainers | Where-Object { $_.name -eq "linkerd-proxy" } | Select-Object -First 1
if (-not $proxy) {
    Write-Host "Could not find linkerd-proxy container on the proxy-injector pod." -ForegroundColor Red
    exit 1
}
$targetImage = $proxy.image
Write-Host "Target proxy image: $targetImage"

# Discover meshed pods. We pull all pods as JSON because (a) jsonpath filters can't easily
# union `initContainers` and `containers`, and (b) iterating in PowerShell is far more readable.
$podsJson = & kubectl --context=$Context get pods -A -o json
$pods = $podsJson | ConvertFrom-Json

# Group by (namespace, app). Pods without the app label group under the synthetic
# app key "<unlabeled>" within their namespace, and are restarted via "no label" selector.
$units = @{}
foreach ($pod in $pods.items) {
    $allContainers = @()
    if ($pod.spec.initContainers) { $allContainers += $pod.spec.initContainers }
    if ($pod.spec.containers)     { $allContainers += $pod.spec.containers }
    $proxyContainer = $allContainers | Where-Object { $_.name -eq "linkerd-proxy" } | Select-Object -First 1
    if (-not $proxyContainer) { continue }

    $ns = $pod.metadata.namespace
    $labels = $pod.metadata.labels
    $app = if ($labels -and $labels.PSObject.Properties[$AppLabel]) { $labels.$AppLabel } else { "<unlabeled>" }
    $image = $proxyContainer.image

    if ($systemNs -contains $ns) { continue }
    if ($ExcludeNamespaces -contains $ns) { continue }
    if ($ExcludeApps -contains $app) { continue }
    if ($IncludeApps.Count -and $IncludeApps -notcontains $app) { continue }

    $key = "$ns/$app"
    if (-not $units.ContainsKey($key)) {
        $units[$key] = @{ Namespace = $ns; App = $app; HasStale = $false; Images = @{} }
    }
    $units[$key].Images[$image] = $true
    if ($image -ne $targetImage) {
        $units[$key].HasStale = $true
    }
}

if ($units.Count -eq 0) {
    Write-Host "No meshed workloads found (after filters)." -ForegroundColor Yellow
    return
}

$staleKeys = @($units.Keys | Where-Object { $units[$_].HasStale } | Sort-Object)
$cleanKeys = @($units.Keys | Where-Object { -not $units[$_].HasStale } | Sort-Object)

Write-Host ""
Write-Host "Already on target ($($cleanKeys.Count) apps):"
foreach ($k in $cleanKeys) { Write-Host "  $k" }

Write-Host ""
Write-Host "To restart ($($staleKeys.Count) apps):"
foreach ($k in $staleKeys) {
    $imgs = ($units[$k].Images.Keys | Sort-Object) -join ", "
    Write-Host "  $k  (current: $imgs)"
}

if ($staleKeys.Count -eq 0) {
    Write-Host ""
    Write-Host "Nothing to do." -ForegroundColor Green
    return
}

if ($DryRun) {
    Write-Host ""
    Write-Host "-DryRun set; no restarts issued."
    return
}

foreach ($k in $staleKeys) {
    $u = $units[$k]
    $ns = $u.Namespace
    $app = $u.App

    # Selector: pin to app label value, or "missing label" for the unlabeled bucket.
    if ($app -eq "<unlabeled>") {
        $selector = "!$AppLabel"
    }
    else {
        $selector = "$AppLabel=$app"
    }

    Write-Host ""
    Write-Host "==> $k"

    # List workloads first so we can wait on them by name.
    # Order: DaemonSets first (infra, log/metric exporters) -- they roll all-nodes at once so
    # do them while the cluster is quietest. Then StatefulSets (usually low replica count, often
    # dependencies of Deployments). Then Deployments last.
    $workloads = & kubectl --context=$Context -n $ns get ds,sts,deploy -l $selector -o name 2>$null |
        Where-Object { $_ }
    if (-not $workloads) {
        Write-Host "    no controller-level matches for selector '$selector'; pods may be bare or label only on pods" -ForegroundColor Yellow
        continue
    }

    foreach ($w in $workloads) {
        Write-Host "    restarting $w"
        & kubectl --context=$Context -n $ns rollout restart $w
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    rollout restart failed for $w" -ForegroundColor Red
            continue
        }
        Write-Host "    waiting on $w..." -NoNewline
        & kubectl --context=$Context -n $ns rollout status $w --timeout="$($RolloutTimeoutSeconds)s" | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host " ok" }
        else { Write-Host " timeout/failed" -ForegroundColor Yellow }
    }
}

Write-Host ""
Write-Host "Done. Re-run to confirm everything reports 'Already on target'."

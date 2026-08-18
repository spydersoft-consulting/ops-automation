<#
    .SYNOPSIS
        Orchestrate a full Linkerd upgrade for one cluster: sync CRDs + control plane,
        roll the meshed proxies, then sync multicluster + viz.

    .DESCRIPTION
        Linkerd is delivered to each cluster as four Argo CD Applications produced by the
        ApplicationSets in ops-argo/cluster-tools/appSets:

            <cluster>-linkerd-crds
            <cluster>-linkerd-control-plane
            <cluster>-linkerd-multicluster
            <cluster>-linkerd-viz

        where <cluster> is the Argo cluster name (nameNormalized). Upgrading by hand means
        syncing those apps in the right order with a proxy roll in the middle. This script
        does the whole dance:

            1. Sync <cluster>-linkerd-crds        and wait Healthy
            2. Sync <cluster>-linkerd-control-plane and wait Healthy
               (the proxy-injector now advertises the NEW proxy image)
            3. Run Restart-AfterLinkerdUpdate.ps1 to roll every meshed workload still on the
               old proxy image -- one app/workload at a time
            4. Sync <cluster>-linkerd-multicluster and wait Healthy (skipped if absent)
            5. Sync <cluster>-linkerd-viz          and wait Healthy (skipped if absent)

        CRDs are synced and confirmed Healthy BEFORE the control plane so new fields the
        control-plane chart references already exist. The proxy roll happens AFTER the control
        plane is Healthy because Restart-AfterLinkerdUpdate.ps1 reads the desired proxy image
        from the running proxy-injector pod -- that pod must already be on the new version.
        Multicluster and viz go LAST: their own proxies are injected with the new image once
        the control plane is up, and viz/multicluster restarts can re-trigger the
        proxy-injector chicken-and-egg problem if done mid-upgrade.

        This assumes the new chart versions are already merged to `main` (e.g. via the
        dependabot-style bump commits) so that `argocd app sync` rolls the cluster forward to
        the committed target revision. It does not touch git.

    .PARAMETER Context
        kubectl context name (internal | nonproduction | production). Required so the proxy
        roll can't hit the wrong cluster. Also used to derive the Argo app prefix unless
        -ArgoAppPrefix is given.

    .PARAMETER ArgoAppPrefix
        Argo cluster name that prefixes the four app names. Defaults are derived from -Context:
            internal      -> in-cluster-local
            nonproduction -> nonproduction
            production    -> production
        Override if your cluster is registered in Argo under a different name.

    .PARAMETER AppNamespace
        Kubernetes namespace the Argo Applications live in. Default "argo". Apps are addressed
        as "<AppNamespace>/<name>" so the CLI resolves them unambiguously.

    .PARAMETER DryRun
        Print the plan (resolved app names, order) and exit. No syncs, no restarts.
        The proxy-roll step is also invoked with -DryRun.

    .PARAMETER SkipRestart
        Sync the apps but do not roll the proxies. Useful if you only want to push chart
        changes and will roll workloads separately.

    .PARAMETER SyncTimeoutSeconds
        Per-app timeout for `argocd app sync` / `argocd app wait`. Default 600.

    .PARAMETER RolloutTimeoutSeconds
        Per-workload rollout timeout passed through to Restart-AfterLinkerdUpdate.ps1. Default 300.

    .PARAMETER ConfirmProduction
        Required to run against a context whose name matches "prod".

    .EXAMPLE
        ./Update-LinkerdCluster.ps1 -Context nonproduction -DryRun

    .EXAMPLE
        ./Update-LinkerdCluster.ps1 -Context nonproduction

    .EXAMPLE
        ./Update-LinkerdCluster.ps1 -Context production -ConfirmProduction
#>

param (
    [Parameter(Mandatory)]
    [string] $Context,
    [string] $ArgoAppPrefix,
    [string] $AppNamespace = "argo",
    [switch] $DryRun,
    [switch] $SkipRestart,
    [int] $SyncTimeoutSeconds = 600,
    [int] $RolloutTimeoutSeconds = 300,
    [switch] $ConfirmProduction
)

$ErrorActionPreference = "Stop"

# ---- production guard (same heuristic as Restart-AfterLinkerdUpdate.ps1) -------------------
if ($Context -match "(?<!non[-_]?)prod" -and -not $ConfirmProduction) {
    Write-Host "Context '$Context' looks like production. Re-run with -ConfirmProduction to proceed." -ForegroundColor Yellow
    exit 2
}

# ---- resolve the Argo app prefix from the context -----------------------------------------
if (-not $ArgoAppPrefix) {
    $prefixMap = @{
        "internal"      = "in-cluster-local"
        "nonproduction" = "nonproduction"
        "production"    = "production"
    }
    if ($prefixMap.ContainsKey($Context)) {
        $ArgoAppPrefix = $prefixMap[$Context]
    }
    else {
        Write-Host "No default Argo app prefix for context '$Context'. Pass -ArgoAppPrefix explicitly." -ForegroundColor Red
        exit 2
    }
}

# Apps are created in the $AppNamespace namespace (app-of-apps / applications-in-any-namespace),
# so they must be addressed as "<namespace>/<name>" to be unambiguous.
$crdsApp         = "$AppNamespace/$ArgoAppPrefix-linkerd-crds"
$controlPlaneApp = "$AppNamespace/$ArgoAppPrefix-linkerd-control-plane"
$multiclusterApp = "$AppNamespace/$ArgoAppPrefix-linkerd-multicluster"
$vizApp          = "$AppNamespace/$ArgoAppPrefix-linkerd-viz"

$restartScript = Join-Path $PSScriptRoot "Restart-AfterLinkerdUpdate.ps1"
if (-not (Test-Path $restartScript)) {
    Write-Host "Cannot find Restart-AfterLinkerdUpdate.ps1 next to this script ($restartScript)." -ForegroundColor Red
    exit 1
}

Write-Host "Linkerd upgrade plan for context '$Context' (Argo cluster '$ArgoAppPrefix')"
Write-Host "  1. sync $crdsApp          (wait Healthy)"
Write-Host "  2. sync $controlPlaneApp  (wait Healthy)"
if ($SkipRestart) {
    Write-Host "  3. (proxy roll skipped: -SkipRestart)"
}
else {
    Write-Host "  3. roll meshed proxies via Restart-AfterLinkerdUpdate.ps1"
}
Write-Host "  4. sync $multiclusterApp  (wait Healthy, skipped if absent)"
Write-Host "  5. sync $vizApp           (wait Healthy, skipped if absent)"
Write-Host ""

# ---- verify argocd CLI is logged in (skipped on a dry run, which makes no server calls) ----
if (-not $DryRun) {
    $userInfo = & argocd account get-user-info 2>&1
    if ($LASTEXITCODE -ne 0 -or ($userInfo -match 'Logged In:\s*false')) {
        Write-Host "argocd CLI is not logged in. Run 'argocd login <server>' first." -ForegroundColor Red
        Write-Host "  ($userInfo)" -ForegroundColor DarkGray
        exit 1
    }
}

# ---- helpers ------------------------------------------------------------------------------

# Returns $true if the named Argo Application exists.
function Test-ArgoApp {
    param([string] $App)
    $null = & argocd app get $App -o json 2>$null
    return ($LASTEXITCODE -eq 0)
}

# Sync an app and wait for it to report Healthy. $Required controls whether a missing app is
# fatal (control-plane stack) or merely skipped (multicluster/viz, which not every cluster has).
function Sync-ArgoApp {
    param(
        [string] $App,
        [switch] $Required
    )

    if ($DryRun) {
        Write-Host "==> $App : sync (wait Healthy)" -ForegroundColor Cyan
        Write-Host "    -DryRun set; would 'argocd app sync $App' then wait Healthy."
        return
    }

    if (-not (Test-ArgoApp -App $App)) {
        if ($Required) {
            Write-Host "==> $App : NOT FOUND in Argo (required) -- aborting." -ForegroundColor Red
            exit 1
        }
        Write-Host "==> $App : not present on this cluster; skipping." -ForegroundColor DarkGray
        return
    }

    Write-Host "==> $App : sync" -ForegroundColor Cyan
    & argocd app sync $App --timeout $SyncTimeoutSeconds
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    sync failed for $App." -ForegroundColor Red
        exit 1
    }

    Write-Host "    waiting for $App to be Healthy..." -NoNewline
    & argocd app wait $App --health --timeout $SyncTimeoutSeconds | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ok"
    }
    else {
        Write-Host " not Healthy within ${SyncTimeoutSeconds}s." -ForegroundColor Red
        exit 1
    }
}

# ---- 1 & 2: CRDs, then control plane ------------------------------------------------------
Sync-ArgoApp -App $crdsApp -Required
Sync-ArgoApp -App $controlPlaneApp -Required

# ---- 3: roll the meshed proxies -----------------------------------------------------------
if ($SkipRestart) {
    Write-Host ""
    Write-Host "==> proxy roll skipped (-SkipRestart)." -ForegroundColor DarkGray
}
else {
    Write-Host ""
    Write-Host "==> rolling meshed proxies" -ForegroundColor Cyan
    $restartArgs = @{
        Context               = $Context
        RolloutTimeoutSeconds = $RolloutTimeoutSeconds
    }
    if ($DryRun)            { $restartArgs.DryRun = $true }
    if ($ConfirmProduction) { $restartArgs.ConfirmProduction = $true }
    & $restartScript @restartArgs
    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
        Write-Host "    proxy roll reported a non-zero exit ($LASTEXITCODE)." -ForegroundColor Yellow
    }
}

# ---- 4 & 5: multicluster, then viz --------------------------------------------------------
Write-Host ""
Sync-ArgoApp -App $multiclusterApp
Sync-ArgoApp -App $vizApp

Write-Host ""
if ($DryRun) {
    Write-Host "-DryRun complete; nothing was changed."
}
else {
    Write-Host "Linkerd upgrade complete for '$Context'." -ForegroundColor Green
    Write-Host "Tip: re-run Restart-AfterLinkerdUpdate.ps1 -Context $Context -DryRun to confirm all apps report 'Already on target'."
}

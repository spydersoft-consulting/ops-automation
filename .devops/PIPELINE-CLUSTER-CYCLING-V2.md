# RKE2 Cluster Cycling Pipeline V2

## Overview

The V2 cluster cycling pipelines provide a comprehensive, phased approach to cycling RKE2 cluster nodes with zero downtime. This version addresses all identified issues from manual processes and adds robust health checks, monitoring, and safety measures.

## Architecture

The V2 template uses a **4-stage pipeline** architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                     CYCLING ORCHESTRATOR                     │
│            (Azure DevOps Pipeline Controller)                │
└─────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┬───────────┐
         ▼                    ▼                    ▼           ▼
    ┌─────────┐         ┌─────────┐         ┌─────────┐  ┌─────────┐
    │ Stage 0 │────────▶│ Stage 1 │────────▶│ Stage 2 │─▶│ Stage 3 │
    │Pre-Flight         │ Servers │         │ Agents  │  │PostCheck│
    └─────────┘         └─────────┘         └─────────┘  └─────────┘
         │                    │                    │           │
         ▼                    ▼                    ▼           ▼
   Diagnostics         Health Checks         Monitoring   Validation
                       Manual Approval       Manual Approval
```

## Pipeline Files

### Template
- **[template-clustercycle-v2.yaml](template-clustercycle-v2.yaml)** - Main reusable template with all cycling logic

### Cluster Pipelines
- **[pipeline-cycle-nonprod-v2.yaml](pipeline-cycle-nonprod-v2.yaml)** - Nonprod cluster (Sundays, 8 PM)
- **[pipeline-cycle-internal-v2.yaml](pipeline-cycle-internal-v2.yaml)** - Internal cluster (Sundays, 9 PM)
- **[pipeline-cycle-prod-v2.yaml](pipeline-cycle-prod-v2.yaml)** - Production cluster (Sundays, 10 PM)

## Pipeline Stages

### Stage 0: Pre-Flight Validation

**Purpose:** Ensure cluster is ready for cycling before making any changes

**Checks:**
- ✅ Cluster connectivity and health
- ✅ Minimum node counts (servers >= minServerCount, agents >= minAgentCount)
- ✅ Production service dependencies (Unifi API, Identity Server)
- ✅ Proxmox storage capacity (>25% free)
- ✅ No pending node drains or critical alerts
- ✅ Cluster-wide PodDisruptionBudgets validation

**Duration:** ~5 minutes

**Exit Criteria:** All health checks must pass to proceed

---

### Stage 1: Server Node Cycling

**Purpose:** Replace control plane nodes maintaining N+1 quorum

**Strategy:** Rolling replacement one server at a time

**Steps:**
1. **Manual Approval Gate** - Requires user approval to proceed
2. **Provision New Servers** - Sequential provisioning with I/O throttling
3. **Wait for Node Ready** - Each server must be ready before provisioning next
4. **Validate etcd Health** - Check etcd cluster health after each addition
5. **Remove Old Servers** - One at a time with quorum protection
6. **Validate After Removal** - Check cluster health after each removal

**Duration:** ~60-120 minutes (depends on server count)

**Safety Features:**
- Never drops below minimum server count (3 for prod, 1 for nonprod)
- Extended drain timeout (15 minutes) with monitoring
- Etcd health validation after each change
- 5-minute delay between operations

---

### Stage 2: Agent Node Cycling

**Purpose:** Replace worker nodes without workload disruption

**Strategy:** Provision all new agents, cordon old agents, drain one at a time

**Steps:**
1. **Manual Approval Gate** - Requires user approval to proceed
2. **Calculate Agent Count** - Determine how many agents to provision
3. **Provision New Agents** - Sequential provisioning (one at a time) with I/O throttling
4. **Wait for Agents Ready** - All agents must be ready before proceeding
5. **Cordon Old Agents** - All at once to prevent new pod scheduling
6. **Drain and Remove Agents** - One at a time with comprehensive monitoring
7. **Post-Drain Validation** - Check pod health after each drain

**Duration:** ~120-240 minutes (depends on agent count and VM size)

**Safety Features:**
- Sequential provisioning to prevent I/O saturation (30-40 MiB/s bandwidth limit)
- Real-time drain monitoring with pod categorization
- PodDisruptionBudget awareness
- Extended drain timeout (30 minutes)
- Decision points for stuck drains
- Post-drain health validation

---

### Stage 3: Post-Cycle Validation

**Purpose:** Confirm cluster health and capacity after cycling

**Steps:**
1. **Cluster Health Check** - Overall cluster status
2. **Node Status** - Verify all nodes are Ready
3. **Unhealthy Pods** - Check for failed or pending pods
4. **Cluster Capacity** - Verify CPU/memory utilization
5. **Application Endpoints** - Test critical services (optional)

**Duration:** ~5 minutes

**Exit Criteria:**
- All nodes Ready
- No unhealthy pods (or acceptable count with warnings)
- Capacity within normal ranges

---

### Stage 4: DNS Refresh

**Purpose:** Restart nginx proxy to refresh DNS cache

**Condition:** Only runs if servers or agents were actually changed

**Steps:**
1. SSH to m5proxy
2. Restart nginx service
3. Wait for service to stabilize

**Duration:** ~30 seconds

---

## Parameters

The V2 template supports the following parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `clusterName` | string | (required) | Name of the cluster to cycle |
| `dnsDomain` | string | `gerega.net` | DNS domain for nodes |
| `serverVmSize` | string | `med` | Server VM size (small, med, large) |
| `agentVmSize` | string | `large` | Agent VM size (small, med, large) |
| `dryRun` | boolean | `false` | Simulate changes without applying |
| `maxAgeDays` | number | `14` | Age threshold for cycling nodes |
| `useStageUnifi` | boolean | `false` | Use staging Unifi API |
| `minServerCount` | number | `3` | Minimum server nodes (quorum protection) |
| `minAgentCount` | number | `3` | Minimum agent nodes |
| `maxConcurrentProvision` | number | `1` | Max concurrent VM provisions (I/O throttling) |
| `maxServersPerRun` | number | `0` | Max servers to cycle per run (0 = unlimited) |
| `maxAgentsPerRun` | number | `0` | Max agents to cycle per run (0 = unlimited) |
| `skipServerCycling` | boolean | `false` | Skip server cycling stage |
| `skipAgentCycling` | boolean | `false` | Skip agent cycling stage |
| `rke2Version` | string | `""` | Specific RKE2 version (e.g., "v1.28.5+rke2r1"). Takes precedence over rke2Channel. |
| `rke2Channel` | string | `stable` | RKE2 channel (stable, latest, testing, or v1.xx). Ignored if rke2Version is set. |

### Version Control Parameters

**NEW:** RKE2 version control allows you to pin clusters to specific versions or track release channels.

- **rke2Version**: Pin to a specific version for production stability (e.g., `"v1.28.5+rke2r1"`)
- **rke2Channel**: Track a release channel for automatic updates (e.g., `"stable"`, `"v1.28"`)

When `rke2Version` is specified, it takes precedence over `rke2Channel`.

See [RKE2 Version Control Documentation](../../provisioning-projects/docs/rke2-version-control.md) for detailed usage and examples.

## Schedule Configuration

Pipelines run on **Sunday evenings** with staggered start times:

- **Nonprod:** 8:00 PM (20:00)
- **Internal:** 9:00 PM (21:00)
- **Production:** 10:00 PM (22:00)

This staggering allows:
1. Nonprod to complete first (least critical)
2. Internal to run next
3. Production to run last after others succeed

**Cron Expression Format:** `"0 HH * * 0"` where HH is the hour in 24-hour format

To modify schedule, edit the `schedules` section in each pipeline file:

```yaml
schedules:
  - cron: "0 20 * * 0"  # Sunday at 8 PM
    displayName: "Nonprod Cluster Cycling (Sunday 8 PM)"
    branches:
      include:
        - main
    always: false  # Only run if there have been changes
```

## Manual Approval Gates

The V2 pipelines include **two manual approval gates**:

1. **After Pre-Flight Validation** - Before server cycling
2. **After Server Cycling** - Before agent cycling

**Timeout:** 24 hours (1440 minutes)

**To Approve:**
1. Go to Azure DevOps pipeline run
2. Review pre-flight/server cycling results
3. Click "Approve" to continue or "Reject" to stop

**Auto-Reject:** If no action is taken within 24 hours, the pipeline will automatically reject and stop

## Dry Run Mode

To test the pipeline without making changes:

1. Go to Azure DevOps
2. Run the pipeline manually
3. Set `dryRun` parameter to `true`

In dry run mode:
- All validation checks run normally
- Shows which nodes would be cycled
- No VMs are provisioned or removed
- No changes to cluster

## PowerShell Functions Required

The V2 pipeline depends on the following Phase 1 functions being implemented in the provisioning modules:

### Health & Validation Functions
- `Test-ClusterReadyForCycling` - Pre-flight cluster validation
- `Test-ProductionServicesAvailable` - Check Unifi/Identity dependencies
- `Test-ProxmoxStorageCapacity` - Check Proxmox storage space
- `Test-ClusterHealth` - Post-cycle cluster health check
- `Get-UnhealthyPods` - List unhealthy pods
- `Get-ClusterNodeInfo` - Get node status information
- `Get-ClusterCapacity` - Get cluster CPU/memory capacity

### Cycling Functions
- `Invoke-Rke2ServerCycling` - Complete server cycling workflow
- `Invoke-Rke2AgentCycling` - Complete agent cycling workflow
- `Get-Rke2AgedNodes` - Get nodes older than threshold

### Supporting Functions
- `Start-NodeDrainWithMonitoring` - Drain with real-time monitoring
- `Wait-K8NodeReady` - Wait for node to become Ready
- `Wait-DnsRecord` - Wait for DNS propagation
- `Invoke-UnifiApiWithRetry` - Retry wrapper for Unifi API calls

## Error Handling

### Pre-Flight Failures
If pre-flight validation fails:
- Pipeline stops before making any changes
- Review validation output
- Fix identified issues
- Re-run pipeline

### Server Cycling Failures
If server cycling fails:
- Agent cycling will not run
- Old servers remain in cluster (may be cordoned)
- Review error output
- Manual intervention may be required to:
  - Uncordon nodes
  - Validate cluster state
  - Retry cycling

### Agent Cycling Failures
If agent cycling fails:
- Some new agents may be provisioned
- Some old agents may be drained/removed
- Review error output and drain diagnostics
- Options:
  - Continue cycling manually
  - Uncordon remaining old agents
  - Remove partially cycled nodes

### Stuck Drains
If a node drain gets stuck:
- Pipeline provides real-time monitoring output
- Shows pods still on node
- Identifies PodDisruptionBudget blockers
- Provides decision point: Continue, Skip, or Abort
- Diagnostic functions available for troubleshooting

## Monitoring & Observability

### Pipeline Logs
Detailed logging at each stage:
- 📊 Progress indicators with colors
- 📋 Pod categorization (DaemonSets, StatefulSets, Deployments)
- ⚠️ Warnings for potential issues
- ✅ Success confirmations

### Key Metrics Logged
- Nodes added/removed count
- Drain progress (% evacuated)
- Pod health status
- Cluster capacity utilization
- I/O delay on Proxmox storage
- API call success/failure

### Post-Pipeline Review
After pipeline completes:
1. Review "Post-Cycle Validation" stage output
2. Check node ages to verify cycling occurred
3. Verify no unhealthy pods
4. Check cluster capacity matches expectations

## Differences from V1

| Feature | V1 | V2 |
|---------|----|----|
| **Structure** | Single job | 4-stage pipeline |
| **Pre-Flight** | None | Comprehensive validation |
| **Approvals** | None | 2 manual gates |
| **Monitoring** | Basic | Real-time with diagnostics |
| **I/O Throttling** | None | Sequential + bandwidth limit |
| **Drain Monitoring** | None | Real-time progress tracking |
| **Health Checks** | Basic | Multi-point validation |
| **Dry Run** | No | Yes |
| **Error Handling** | Basic | Decision points & diagnostics |
| **Documentation** | Minimal | Comprehensive |

## Rollout Plan

### Phase 1: Testing (Weeks 3-4)
1. ✅ Create V2 template and pipelines
2. Run dry-run mode on nonprod cluster
3. Review output and logs
4. Fix any issues discovered

### Phase 2: Nonprod Pilot (Week 5)
1. Disable V1 nonprod pipeline schedule
2. Run V2 nonprod pipeline manually
3. Monitor throughout execution
4. Validate cluster health post-cycle
5. Document any issues

### Phase 3: Scheduled Nonprod (Week 6)
1. Enable V2 nonprod pipeline schedule
2. Let run on Sunday evening
3. Review Monday morning
4. Iterate on issues

### Phase 4: Internal & Production (Weeks 7-8)
1. Repeat pilot process for internal cluster
2. After 2 successful internal runs, pilot production
3. Enable production schedule
4. Monitor closely for 4 weeks

### Phase 5: Decommission V1 (Week 9+)
1. After 4 successful production cycles
2. Archive V1 pipelines (rename with .old extension)
3. Update documentation
4. Operational handoff complete

## Troubleshooting

### Pipeline won't start
- Check schedule configuration
- Verify branch is `main`
- Check if `always: false` and no changes since last run

### Pre-flight fails on storage
- Check Proxmox storage capacity
- May need to clean up old snapshots or VMs
- Temporarily lower threshold or add storage

### Server cycling slow
- Expected: ~10-15 minutes per server
- Check I/O delay on Proxmox
- Review bandwidth limit settings

### Agent drain stuck
- Review drain monitoring output
- Check for PodDisruptionBudget violations
- May need to scale up replicas temporarily
- Use diagnostic functions to identify blockers

### DNS not propagating
- Pipeline includes DNS wait logic
- If fails, check m5proxy service status
- Verify Unifi DNS records created
- May need manual nginx restart

## Related Documentation

- [RKE2 Cluster Cycling Automation Plan](../../provisioning-projects/docs/rke2-cluster-cycling-automation-plan.md) - Complete architecture and design
- [Phase 1 Implementation](../../provisioning-projects/docs/phase1-implementation.md) - PowerShell functions (if exists)

## Support

For issues or questions:
1. Review pipeline logs for detailed error messages
2. Check this documentation for troubleshooting steps
3. Use diagnostic PowerShell functions for investigation
4. Consult the automation plan document for design details

---

**Version:** 2.0
**Last Updated:** 2026-01-30
**Author:** RKE2 Automation Team

# Ops health sweep

One command gathers everything an agent (or you) needs to judge cluster health, so review
takes a single tool call instead of dozens of exploratory `kubectl`/`ssh` round trips.

    pwsh scripts/health/Invoke-OpsHealth.ps1            # everything, ~20-40s
    pwsh scripts/health/Invoke-OpsHealth.ps1 -SkipProxmox -Clusters production
    # or from Claude Code: just ask about cluster health (personal skill ~/.claude/skills/cluster-health)

Output: a compact markdown report on stdout, also saved to `scripts/health/out/<timestamp>/`
(`report.md`, per-source `.md`, and `latest.md`). `out/` is git-ignored.

## What is checked

| Source | Checks |
|---|---|
| Each kube context (`internal`, `nonproduction`, `production`) | API readyz; node Ready/pressure/cordon/unexpected taints/version skew; node CPU/mem >=85% (metrics-server); pods CrashLoop/ImagePull/Pending/not-Ready/stuck-Terminating/high recent restarts; Failed pods (collapsed per reason); Deployment/StatefulSet/DaemonSet ready < desired; failed Jobs; unbound PVCs; PDBs allowing 0 disruptions; cert-manager Certificates, ExternalSecrets, ArgoCD Applications (only if the CRD exists); digest of Warning events in the last hour |
| Alerts: Mimir (`https://mimir.mattgerega.net`, tenants = cluster names) + Grafana-managed rules (`grafana.mattgerega.net`, admin creds read at runtime from `monitoring/grafana-admin-secret` on the `internal` context, never stored) | firing alerts (grouped by alertname), pending alerts (INFO), active Alertmanager alerts not seen in the ruler, rules failing to evaluate |
| Proxmox cluster (via `pvesh` on first reachable host) | quorum; node online; storage availability and >=85/92% full; guests stopped / >=95% mem; failed tasks (backups etc.) in last 24h |
| Each Proxmox host (`proxmox-host-check.sh`, read-only, over ssh) | PVE services; failed units; load/mem/swap; fs and LVM-thin/ZFS/Ceph capacity; SMART; ECC counters; NTP; recent reboot; 24h kernel-log signatures (MCE, io_uring, DMAR, fs/IO errors, oops, OOM, NIC flap, iSCSI) |

Healthy checks are collapsed into a single `Clean:` line. Severity: CRIT = broken now,
WARN = degraded/will bite soon, INFO = context.

## Requirements / assumptions

- PowerShell 7, `kubectl` and `ssh` on PATH (winget links: `~/bin/fix-winget-links.sh`).
- kube contexts named `internal`, `nonproduction`, `production`.
- Key-based root SSH to the Proxmox hosts (`-ProxmoxHosts` to change the list).
- Strictly read-only. Nothing is modified on any cluster or host.

## Extending

- New k8s check: add a block to `k8s-health.ps1` using `Add-Finding <CRIT|WARN|INFO> <area> <text>`
  and `$ran.Add('<area>')` so it shows up under `Clean:` when empty.
- New host check: add a line to `proxmox-host-check.sh` that echoes `[CRIT]/[WARN]/[INFO] text`.
- Keep collectors anomaly-only; the whole point is a small report.

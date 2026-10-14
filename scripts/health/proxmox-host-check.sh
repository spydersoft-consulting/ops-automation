#!/bin/bash
# Runs ON a Proxmox host (piped over ssh by proxmox-health.ps1). Read-only.
# Emits only tagged lines: [CRIT] / [WARN] / [INFO]. Silence == healthy.
export LC_ALL=C
crit() { echo "[CRIT] $*"; }
warn() { echo "[WARN] $*"; }
info() { echo "[INFO] $*"; }

info "$(pveversion 2>/dev/null | head -1) | kernel $(uname -r) | $(uptime -p) | load $(cut -d' ' -f1-3 /proc/loadavg) on $(nproc) cpu"

# --- PVE services ---
for s in pve-cluster corosync pvedaemon pveproxy pvestatd pve-ha-lrm pve-ha-crm; do
  st=$(systemctl is-active "$s" 2>/dev/null)
  [ "$st" = "active" ] || crit "service $s is '$st'"
done
failed=$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}' | paste -sd, -)
[ -n "$failed" ] && warn "failed systemd units: $failed"

# --- load / memory / swap ---
awk -v n="$(nproc)" '{ if ($3 > n*1.5) printf "[WARN] 15m load %.1f exceeds 1.5x cpu count (%d)\n", $3, n }' /proc/loadavg
free -m | awk '
  /^Mem:/  { pct = ($2-$7)*100/$2; if (pct >= 90) printf "[WARN] memory %d%% used (%d of %d MB, available %d)\n", pct, $2-$7, $2, $7 }
  /^Swap:/ { if ($2 > 0 && $3*100/$2 >= 50) printf "[WARN] swap %d%% used (%d of %d MB)\n", $3*100/$2, $3, $2 }'

# --- uptime: recent reboot ---
up=$(cut -d. -f1 /proc/uptime)
[ "$up" -lt 86400 ] && warn "host rebooted $((up/3600))h ago"

# --- filesystems ---
df -P -x tmpfs -x devtmpfs -x squashfs -x overlay -x fuse 2>/dev/null | awk 'NR>1 { p=$5+0; if (p>=95) printf "[CRIT] fs %s at %d%%\n", $6, p; else if (p>=85) printf "[WARN] fs %s at %d%%\n", $6, p }'

# --- LVM thin pools ---
lvs --noheadings --separator '|' -o lv_name,vg_name,data_percent,metadata_percent 2>/dev/null | awk -F'|' '
  { gsub(/ /,"",$1); gsub(/ /,"",$2); d=$3+0; m=$4+0;
    if ($3 != "" && (d>=95 || m>=95)) printf "[CRIT] thin pool %s/%s data %.0f%% meta %.0f%%\n", $2,$1,d,m;
    else if ($3 != "" && (d>=85 || m>=85)) printf "[WARN] thin pool %s/%s data %.0f%% meta %.0f%%\n", $2,$1,d,m }'

# --- ZFS ---
if command -v zpool >/dev/null 2>&1 && [ -n "$(zpool list -H 2>/dev/null)" ]; then
  z=$(zpool status -x 2>&1)
  echo "$z" | grep -q "all pools are healthy" || crit "zpool: $(echo "$z" | tr '\n' ' ' | cut -c1-300)"
  zpool list -H -o name,capacity 2>/dev/null | awk '{ c=$2+0; if (c>=85) printf "[WARN] zpool %s at %d%%\n", $1, c }'
fi

# --- Ceph (if present) ---
if command -v ceph >/dev/null 2>&1 && [ -f /etc/pve/ceph.conf ]; then
  h=$(timeout 10 ceph health 2>&1 | head -1)
  case "$h" in HEALTH_OK*) ;; *) warn "ceph: $h" ;; esac
fi

# --- SMART ---
if command -v smartctl >/dev/null 2>&1; then
  for d in $(lsblk -dn -o NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1}'); do
    out=$(smartctl -H -A "/dev/$d" 2>/dev/null)
    echo "$out" | grep -qE "overall-health.*(FAILED|FAIL)|Health Status:.*FAIL|FAILING_NOW" && crit "SMART health FAILED on /dev/$d"
    echo "$out" | awk -v d="$d" '
      /Percentage Used/                 { v=$NF+0; if (v>=80) printf "[WARN] /dev/%s NVMe wear %d%% used\n", d, v }
      /Media and Data Integrity Errors/ { v=$NF+0; if (v>0)   printf "[WARN] /dev/%s media/data integrity errors: %d\n", d, v }
      /Critical Warning/                { if ($NF != "0x00") printf "[WARN] /dev/%s NVMe critical warning %s\n", d, $NF }
      /Reallocated_Sector_Ct|Current_Pending_Sector|Offline_Uncorrectable/ { v=$NF+0; if (v>0) printf "[WARN] /dev/%s %s=%d\n", d, $2, v }'
  done
fi

# --- ECC memory error counters (if EDAC loaded) ---
for f in /sys/devices/system/edac/mc/mc*/ue_count; do
  [ -r "$f" ] && [ "$(cat "$f")" -gt 0 ] && crit "uncorrectable ECC errors: $f=$(cat "$f")"
done
for f in /sys/devices/system/edac/mc/mc*/ce_count; do
  [ -r "$f" ] && [ "$(cat "$f")" -gt 0 ] && warn "correctable ECC errors: $f=$(cat "$f")"
done

# --- time sync ---
[ "$(timedatectl show -p NTPSynchronized --value 2>/dev/null)" = "yes" ] || warn "clock not NTP-synchronized"

# --- kernel log, last 24h: count by signature, show one sample each ---
klog=$(journalctl -k --since "24 hours ago" --no-pager -q 2>/dev/null)
scan() { # label, extended regex
  local n; n=$(echo "$klog" | grep -ciE "$2")
  [ "$n" -gt 0 ] && warn "kernel 24h: $1 x$n; last: $(echo "$klog" | grep -iE "$2" | tail -1 | cut -c1-220)"
}
scan "machine check / hardware error" 'mce:|machine check|hardware error'
scan "io_uring fault"                 'io_uring'
scan "IOMMU/DMAR fault"               'DMAR:.*fault|DMAR.*error|AMD-Vi.*(fault|error)'
scan "filesystem/IO error"            'EXT4-fs (error|warning)|EXT4-fs.*abort|I/O error|blk_update_request|XFS.*(error|corrupt)'
scan "kernel oops/BUG/panic"          'Oops|BUG:|general protection fault|kernel panic|Call Trace'
scan "OOM kill"                       'out of memory|oom-kill'
scan "NIC/link flap"                  'NIC Link is Down|link is down|tx timeout|Detected Tx Unit Hang'
scan "storage/iSCSI trouble"          'iscsi.*(error|timeout|reset)|connection[0-9]+:[0-9]+: detected conn error'
exit 0

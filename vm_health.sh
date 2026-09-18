#!/usr/bin/env bash
# Report the health of a Linux VM from CPU, memory, and root filesystem usage.

set -u

readonly THRESHOLD=60
readonly SAMPLE_SECONDS=1

explain=false
if [[ $# -gt 1 || ( $# -eq 1 && $1 != "explain" ) ]]; then
    printf 'Usage: %s [explain]\n' "$0" >&2
    exit 2
fi
if [[ ${1:-} == "explain" ]]; then
    explain=true
fi

# Read the aggregate CPU counters from /proc/stat.
read_cpu_counters() {
    awk '/^cpu / { print $2, $3, $4, $5, $6, $7, $8, $9; exit }' /proc/stat
}

cpu_before=$(read_cpu_counters)
sleep "$SAMPLE_SECONDS"
cpu_after=$(read_cpu_counters)

read -r user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 <<< "$cpu_before"
read -r user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 <<< "$cpu_after"

total1=$((user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1 + steal1))
total2=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2))
idle_delta=$(( (idle2 + iowait2) - (idle1 + iowait1) ))
total_delta=$((total2 - total1))

if (( total_delta > 0 )); then
    cpu_used=$(( (100 * (total_delta - idle_delta)) / total_delta ))
else
    cpu_used=0
fi

# free(1)'s available memory is the best approximation of memory that can be
# allocated without swapping, so calculate usage from total - available.
read -r memory_total memory_available < <(free -m | awk '/^Mem:/ { print $2, $7 }')
if [[ -z ${memory_total:-} || -z ${memory_available:-} || $memory_total -eq 0 ]]; then
    printf 'Unable to determine memory utilization.\n' >&2
    exit 1
fi
memory_used=$(( (100 * (memory_total - memory_available)) / memory_total ))

disk_used=$(df -P / | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }')
if [[ -z ${disk_used:-} ]]; then
    printf 'Unable to determine disk utilization for /.\n' >&2
    exit 1
fi

status="Healthy"
if (( cpu_used >= THRESHOLD || memory_used >= THRESHOLD || disk_used >= THRESHOLD )); then
    status="Not Healthy"
fi

printf 'VM Health: %s\n' "$status"
if [[ $explain == true ]]; then
    printf 'Threshold: less than %d%% utilization is healthy; %d%% or more is not healthy.\n' "$THRESHOLD" "$THRESHOLD"
    printf 'CPU utilization: %d%% (%s)\n' "$cpu_used" "$( (( cpu_used < THRESHOLD )) && printf 'healthy' || printf 'above threshold' )"
    printf 'Memory utilization: %d%% (%s)\n' "$memory_used" "$( (( memory_used < THRESHOLD )) && printf 'healthy' || printf 'above threshold' )"
    printf 'Disk utilization (/): %d%% (%s)\n' "$disk_used" "$( (( disk_used < THRESHOLD )) && printf 'healthy' || printf 'above threshold' )"
fi

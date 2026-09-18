# AIOps VM Health Check

A small Linux shell utility that reports whether a virtual machine is **Healthy** or **Not Healthy** by checking CPU, memory, and root disk utilization.

## What this repository does

The `vm_health.sh` script:

1. Samples aggregate CPU counters for one second and calculates CPU utilization.
2. Reads total and available memory using `free` and calculates memory utilization.
3. Checks the filesystem containing `/` using `df` and reads its utilization.
4. Reports `Healthy` only when **all three** utilization values are below 60%.
5. Reports `Not Healthy` when CPU, memory, or root disk utilization is 60% or higher.
6. Supports an optional `explain` argument that prints each measured value and why it contributed to the result.

## Requirements

- Linux operating system
- Bash 4 or newer
- `awk`, `df`, `free`, and `sleep`
- Permission to read `/proc/stat` (normally available to all users)

The script is intended for Linux VMs because it uses `/proc/stat` and Linux `free` output.

## Usage

Make the script executable:

```bash
chmod +x vm_health.sh
```

Print only the overall health status:

```bash
./vm_health.sh
```

Example:

```text
VM Health: Healthy
```

Print the status and the measurements behind it:

```bash
./vm_health.sh explain
```

Example:

```text
VM Health: Not Healthy
Threshold: less than 60% utilization is healthy; 60% or more is not healthy.
CPU utilization: 23% (healthy)
Memory utilization: 71% (above threshold)
Disk utilization (/): 42% (healthy)
```

An invalid argument prints the usage message and exits with status `2`.

## Health rules

| Resource | Healthy | Not Healthy |
|---|---:|---:|
| CPU | `< 60%` | `>= 60%` |
| Memory | `< 60%` | `>= 60%` |
| Root disk (`/`) | `< 60%` | `>= 60%` |

The result is `Not Healthy` if **any** resource reaches or exceeds the threshold. A value exactly equal to 60% is therefore treated as not healthy, removing ambiguity at the boundary.

### Measurement details

- **CPU:** The script compares the aggregate `cpu` line in `/proc/stat` before and after a one-second interval. Time spent idle and in I/O wait is excluded from the used percentage.
- **Memory:** Usage is calculated as `(total memory - available memory) / total memory`. Linux's `available` value is used rather than only `free`, since it better represents memory that can be allocated without swapping.
- **Disk:** The script checks the filesystem mounted at `/`, not every mounted filesystem. Disk percentage comes from `df -P /`.

## Exit status

- `0`: The script ran successfully, regardless of whether the reported state is Healthy or Not Healthy.
- `1`: A required utilization value could not be determined.
- `2`: Invalid command-line arguments.

## Repository layout

```text
.
├── README.md
└── vm_health.sh
```

## Limitations and possible extensions

This is a lightweight point-in-time health check, not a monitoring service. It does not persist metrics, send alerts, inspect individual processes, check network connectivity, or evaluate non-root filesystems. It can be extended with logging, alert integrations, configurable thresholds, additional mount points, or repeated checks.

## License

No license has been selected for this repository yet. Until one is added, the repository contents should not be assumed to be available for redistribution under an open-source license.

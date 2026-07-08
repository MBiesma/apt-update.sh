# Monthly APT Update Script

This repository contains a Linux maintenance script that performs monthly APT updates, logs the update process, and reboots the system automatically after completion.

## Purpose

The script is intended for Debian/Ubuntu-based virtual machines where monthly patching is performed automatically through cron.

It performs the following actions:

- Removes `unattended-upgrades`
- Cleans the APT cache
- Updates package information
- Logs all packages that will be upgraded
- Runs `apt dist-upgrade`
- Runs `apt upgrade`
- Removes unused packages
- Reboots the system after completion

## Script Location

The script is located at:

```bash
/opt/apt-update.sh
```

## Log Location

All output from the script is written to:

```bash
/opt/apt_update/
```

The logfile name contains the hostname and the execution date.

Example:

```text
/opt/apt_update/update_eqxrelay01_2026-07-01.log
```

If the server has a fully qualified domain name, the logfile may look like this:

```text
/opt/apt_update/update_eqxrelay01.example.local_2026-07-01.log
```

## Script

```bash
#!/bin/bash

LOGDIR="/opt/apt_update"
HOSTNAME="$(hostname -f 2>/dev/null || hostname)"
DATE="$(date +%F)"
LOGFILE="${LOGDIR}/update_${HOSTNAME}_${DATE}.log"

mkdir -p "$LOGDIR"

# Redirect all stdout and stderr to the log file
exec > "$LOGFILE" 2>&1

echo "============================================================"
echo "APT update started at: $(date)"
echo "Hostname: $HOSTNAME"
echo "Log file: $LOGFILE"
echo "============================================================"
echo

export DEBIAN_FRONTEND=noninteractive

echo "Removing unattended-upgrades..."
/usr/bin/apt --purge remove unattended-upgrades -y

echo
echo "Cleaning APT cache..."
/usr/bin/apt clean

echo
echo "Updating package information..."
/usr/bin/apt update

echo
echo "Packages that will be upgraded:"
echo "------------------------------------------------------------"

/usr/bin/apt list --upgradable 2>/dev/null | awk -F'[ /]+' '
  NR > 1 {
    package=$1
    newversion=$3
    oldversion=$NF
    printf "%50s %35s -> %35s\n", package, oldversion, newversion
  }
'

echo "------------------------------------------------------------"
echo

echo "Running dist-upgrade..."
/usr/bin/apt dist-upgrade -y

echo
echo "Running upgrade..."
/usr/bin/apt upgrade -y

echo
echo "Removing unused packages..."
/usr/bin/apt autoremove -y

echo
echo "APT update completed at: $(date)"
echo "System will now reboot..."
echo "============================================================"

/bin/systemctl reboot -i
```

## Permissions

Make sure the script is executable:

```bash
chmod +x /opt/apt-update.sh
```

## Cron Schedule

The script is scheduled through the root crontab.

View the current crontab:

```bash
crontab -l
```

Current schedule:

```cron
0 7 1 * * /opt/apt-update.sh
```

This means the script runs:

```text
Every 1st day of the month at 07:00 local server time.
```

## Manual Execution

The script can also be started manually:

```bash
/opt/apt-update.sh
```

After completion, the server will reboot automatically.

## Example Log Output

Example logfile:

```text
/opt/apt_update/update_eqxrelay01_2026-07-01.log
```

The log contains:

- Start time
- Hostname
- List of packages that will be upgraded
- APT update output
- APT upgrade output
- Autoremove output
- Reboot notification

Example package upgrade section:

```text
Packages that will be upgraded:
------------------------------------------------------------
                                            apport                  2.20.11-0ubuntu27.29 ->                     2.20.11-0ubuntu27.31
                                           dirmngr                     2.2.19-3ubuntu2.4 ->                        2.2.19-3ubuntu2.5
                                             gnupg                     2.2.19-3ubuntu2.4 ->                        2.2.19-3ubuntu2.5
------------------------------------------------------------
```

## Notes

- The script should be executed as `root`.
- The system reboots automatically after the updates are completed.
- Logs are stored locally under `/opt/apt_update`.
- Existing logs are not automatically removed.
- The cron schedule uses the local timezone of the VM.

## Warning

This script performs unattended package upgrades and reboots the system automatically.  
Only use it on systems where scheduled monthly reboots are allowed.

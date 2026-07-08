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

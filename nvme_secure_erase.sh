#!/usr/bin/env bash
set -euo pipefail

# ===== Basic Configuration =====
TS="$(date +'%Y%m%d_%H%M%S')"
LOG="/var/log/nvme_secure_erase_${TS}.log"
CERT_DIR="/root"
RED=$'\e[31m'; YEL=$'\e[33m'; GRN=$'\e[32m'; NC=$'\e[0m'

# Redirect all output (stdout/stderr) to log file while displaying on screen
exec > >(tee -a "$LOG") 2>&1

echo "==== NVMe Secure Erase Started: ${TS} ===="
echo "Log file: $LOG"
echo

# Detect physical device backing the root filesystem (prevents accidental system erase)
ROOT_SRC="$(findmnt -no SOURCE /)"
ROOT_BASE="/dev/$(lsblk -no PKNAME "$ROOT_SRC" || true)"
[ -z "$ROOT_BASE" ] && ROOT_BASE="$(echo "$ROOT_SRC" | sed -E 's/p?[0-9]+$//')"  # Fallback handling

# Display connected devices for operator reference
echo "■ Connected devices (reference only)"
lsblk -o NAME,SIZE,MODEL,SERIAL,MOUNTPOINT
echo
nvme list || true
echo

# Prompt user to specify target NVMe device (example: /dev/nvme1n1)
read -rp "Enter the NVMe disk to securely erase in /dev/nvmeXN1 format (example: /dev/nvme1n1): " DEV

# Input validation (only whole NVMe disk node allowed, not partitions)
if [[ ! -e "$DEV" ]]; then
  echo "${RED}Error:${NC} Device does not exist: $DEV"; exit 1
fi
if [[ ! "$DEV" =~ ^/dev/nvme[0-9]+n[0-9]+$ ]]; then
  echo "${RED}Error:${NC} Please specify the entire NVMe disk (e.g., /dev/nvmeXN1), not a partition."; exit 1
fi

# Prevent accidental selection of active root disk
if [[ -n "$ROOT_BASE" && "$DEV" == "$ROOT_BASE" ]]; then
  echo "${RED}Danger:${NC} This is the active root disk ($DEV). Operation aborted."
  exit 1
fi

# Final explicit confirmation gate
echo
echo "Final confirmation: The following device will be permanently erased → $DEV"
echo "${YEL}WARNING: This operation is irreversible.${NC}"
read -rp "Type 'YES' in uppercase to proceed: " ANS
if [[ "$ANS" != "YES" ]]; then
  echo "Operation cancelled."; exit 1
fi

# Retrieve device identification information (for audit certificate)
MODEL="$(nvme id-ctrl "$DEV" | awk -F: '/mn/ {sub(/^ +/,"",$2); print $2; exit}' || true)"
SERIAL="$(nvme id-ctrl "$DEV" | awk -F: '/sn/ {sub(/^ +/,"",$2); print $2; exit}' || true)"
FWREV="$(nvme id-ctrl "$DEV" | awk -F: '/fr/ {sub(/^ +/,"",$2); print $2; exit}' || true)"
echo "Target Model : ${MODEL:-N/A}"
echo "Serial Number: ${SERIAL:-N/A}"
echo "FW Revision  : ${FWREV:-N/A}"
echo

# Verify and unmount any mounted partitions before erase
echo "Checking and unmounting mounted partitions..."
for part in $(lsblk -nr "$DEV" -o NAME | tail -n +2); do
  if findmnt -rno TARGET "/dev/$part" >/dev/null 2>&1; then
    echo "umount /dev/$part"
    umount -f "/dev/$part" || true
  fi
done
echo "Unmount check complete."
echo

# Execute NVMe Secure Erase at controller level
echo "${YEL}Executing nvme format (--ses=1: Secure Erase)...${NC}"
time nvme format "$DEV" --ses=1
FMT_RC=$?
echo

if [[ $FMT_RC -ne 0 ]]; then
  echo "${RED}Failure:${NC} nvme format exited with error (rc=$FMT_RC). Check log: $LOG"
  exit $FMT_RC
fi

echo "${GRN}Success:${NC} Secure Erase completed."
echo

echo "Verification: fdisk -l $DEV"
fdisk -l "$DEV" || true
echo

# Generate deletion certificate for audit and compliance records
CERT="${CERT_DIR}/erase_certificate_${SERIAL:-UNKNOWN}_${TS}.txt"
{
  echo "=========== Secure Erase Certificate ==========="
  echo "Device     : $DEV"
  echo "Model      : ${MODEL:-N/A}"
  echo "Serial     : ${SERIAL:-N/A}"
  echo "FW Rev     : ${FWREV:-N/A}"
  echo "Method     : nvme format --ses=1 (NVMe Secure Erase)"
  echo "Host       : $(hostname -f 2>/dev/null || hostname)"
  echo "Kernel     : $(uname -r)"
  echo "Started at : ${TS}"
  echo "Finished at: $(date +'%Y%m%d_%H%M%S')"
  echo "Log file   : $LOG"
  echo "Notes      : All user data blocks invalidated at controller level."
  echo "================================================"
} | tee "$CERT"

echo
echo "${GRN}Deletion certificate:${NC} $CERT"
echo "${GRN}Execution log       :${NC} $LOG"
echo "These files should be retained as proof of secure erase."

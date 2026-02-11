# nvme-secure-erase-tool

Enterprise-grade NVMe Secure Erase automation tool with multi-layer safety controls and audit trail generation (Linux).

> ⚠️ Designed for enterprise infrastructure environments requiring verifiable and irreversible data sanitization.

---

## Overview

This tool automates NVMe Secure Erase operations on Linux systems.

Unlike simple file deletion or filesystem formatting,  
it executes controller-level Secure Erase using:

```bash
nvme format --ses=1
```

The design prioritizes operational risk mitigation, irreversible data sanitization, and traceable execution records.

It is intended for enterprise environments where secure device lifecycle management and compliance verification are required.

---

## Why I Built This

While working in infrastructure operations, I encountered scenarios where:

- SSDs were reused without guaranteed data sanitization
- OS image disks required irreversible destruction
- Internal audits required verifiable deletion records
- Accidental erasure of system disks had to be prevented

This tool was built to address those real-world operational risks.

It focuses on:

- Preventing catastrophic mistakes
- Ensuring controller-level irreversible data destruction
- Generating audit-ready evidence
- Supporting secure asset lifecycle management

---

## Architecture & Flow

Below is the execution flow of the secure erase process:

![NVMe Secure Erase Flow](nvme_secure_erase_flow.png)

The workflow ensures:

- System disk detection
- Explicit human confirmation
- Mount state validation
- Secure erase execution
- Post-erase verification
- Log and certificate generation

---

## Core Safety Design

The script implements multiple layers of protection:

- Automatic detection of the active system disk
- Immediate abort if the system disk is selected
- Explicit `YES` confirmation gate
- Mount state validation and forced unmount
- Execution logging
- Generation of device-identifiable erase certificates (model / serial / timestamp)

These controls significantly reduce operational risk in production environments.

---

## Security & Confidentiality

This public repository is a sanitized and generalized version of tooling developed in enterprise infrastructure environments.

No proprietary information, internal architecture details, or confidential operational data are included.

The implementation has been intentionally abstracted to:

- Protect internal infrastructure details
- Ensure compliance with corporate security policies
- Avoid exposure of production topology or host information

This project demonstrates secure operational design principles while maintaining strict confidentiality boundaries.

---

## Features

- Mounted device detection
- System disk protection
- NVMe device validation
- Human confirmation safeguard
- Controller-level secure erase execution
- Post-erase validation
- Execution logging
- Audit-ready output

---

## What Secure Erase Actually Does

The command:

```
nvme format --ses=1
```

Performs:

- Logical invalidation of all user LBA regions
- Destruction of encryption keys (if enabled)
- Controller-level reset of user data areas

This is **not** a filesystem format.  
It is a hardware-level secure erase operation.

---

## What Gets Completely Erased

- All user files
- All partitions
- All filesystems (ext4, NTFS, etc.)
- Installed operating systems
- Previously deleted residual data
- Disk encryption keys

Data recovery after this process is not possible using software-based recovery tools.

---

## What Cannot Be Erased (By Design)

The following SSD metadata remains, as defined by hardware controller design:

- Power cycle count
- Power-on hours
- Total data written
- Model name
- Serial number
- Firmware version

These are controller-level statistics and do not contain user data.

---

## Audit & Compliance Support

The script generates:

- Execution logs
- Device identification records
- Timestamped erase certificates

This enables verification of:

- When the erase was performed
- Which device was erased
- Which method was used

Suitable for internal audit, compliance validation, and asset disposal documentation.

---

## Script File

The main executable script in this repository is:

- `nvme_secure_erase.sh`

It implements all safety checks and secure erase logic described above.

---

## Requirements

- Linux
- `nvme-cli` installed
- Root privileges

---

## Example Execution

```bash
sudo ./nvme_secure_erase.sh
```

When prompted, enter the target device (example: `/dev/nvme1n1`).

---

## Disclaimer

Use at your own risk.

Always verify the target device before executing Secure Erase.

Although this tool includes multi-layer safety checks, final responsibility remains with the operator.

---

## Author

Takahiro Okawa  
Infrastructure Engineer  
Linux / Automation / Secure Operations

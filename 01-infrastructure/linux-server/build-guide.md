# Phase 1 – Linux Server Build (Privilege Surface)

This guide sets up a **Linux server** that will later be used to demonstrate
**sudo misuse, shared access, SSH risks, and non-human identities**.

The goal is to create a **realistic privilege entry point** for IAM and PAM use cases.

---

##  Purpose of This Phase

You will:
- Build a Linux server
- Join it to the lab network
- Configure basic access
- Prepare it for identity and privilege misuse scenarios

No hardening is applied at this stage — intentionally.

---

## VM Configuration

| Setting | Value |
|------|------|
| VM Name | LNX01 |
| OS | Ubuntu Server 22.04 LTS |
| RAM | 2 GB |
| CPU | 2 vCPU |
| Disk | 20 GB |
| Network | VMnet10 (Host-only) |

---

## Step 1: Create the Virtual Machine

1. Open **VMware Workstation Pro**
2. Create a new virtual machine
3. Select the Ubuntu Server 22.04 ISO
4. Name the VM: `LNX01`
5. Store the VM under:
`D:\iam-pam-homelab\vms`

6. Complete VM creation

No advanced hardware customization is required.

---

## Step 2: Install Ubuntu Server

1. Power on the VM
2. Choose **Install Ubuntu Server**
3. Select language and keyboard
4. Network:
   - Use DHCP for now
5. Storage:
   - Use entire disk
6. Profile setup:
   - Create a local user (example: `linuxadmin`)
   - Set a simple password (lab only)
7. Skip snaps and optional packages
8. Complete installation and reboot

---

## Step 3: Configure Static IP (Optional but Recommended)

Edit netplan configuration:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```
Example configuration:
```bash
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: no
      addresses:
        - 192.168.10.30/24
      nameservers:
        addresses:
          - 192.168.10.10
```
Apply changes:
```bash
sudo netplan apply
```

---

## Step 4: Verify Network Connectivity

Validate connectivity to the Domain Controller:
```bash
ping 192.168.10.10
```
Ensure name resolution works:
```bash
nslookup iamlab.local
```
---

## 🟦 Automation Boundary (Important)

At this stage:
- The Linux server is not domain-joined
- No central identity integration exists
- This reflects a very common enterprise state.

All identity, sudo, and SSH misuse scenarios will be introduced in later phases.

---

## Consultant Notes – Why Linux Matters in PAM

- Linux servers often bypass IAM governance
- SSH keys replace passwords without ownership
- Sudo becomes permanent privilege
- Service accounts live forever

Linux is where non-human identity risk explodes.

---

## ✅ Phase 1 Exit Criteria

You should have:
- LNX01 running
- Network connectivity to DC01
- Local admin-style access via sudo

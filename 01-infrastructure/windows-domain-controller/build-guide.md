# Phase 1 – Windows Domain Controller Build

This guide walks you through building the **first and most critical component** of the lab:
a Windows Server 2022 **Active Directory Domain Controller**.

From this phase onward, **automation is introduced deliberately** to reflect real enterprise practices.

---

##  Purpose of This Phase

You will:
- Install Windows Server 2022
- Configure basic server settings and networking
- Promote the server to a Domain Controller using PowerShell
- Apply a generic Active Directory baseline

---

## Setup - Manual Foundation

### VM Configuration

| Setting | Value |
|------|------|
| VM Name | DC01 |
| OS | Windows Server 2022 |
| RAM | 4 GB |
| CPU | 2 vCPU |
| Disk | 40 GB |
| Network | VMnet10 (Host-only) |

---

## Step 1: Create the Virtual Machine

1. Open **VMware Workstation Pro**
2. Click **Create a New Virtual Machine**
3. Select **Typical**
4. Choose **Installer disc image file (ISO)**
5. Select the Windows Server 2022 ISO
6. Guest OS:
   - Microsoft Windows
   - Version: Windows Server 2022
7. Name the VM: `DC01`
8. VM location: `D:\iam-pam-homelab\vms`
9. Disk size: `40 GB`
10. Store virtual disk as a single file
11. Finish

---

## Step 2: Install Windows Server 2022

1. Power on the VM
2. Select language and region
3. Click **Install Now**
4. Choose:
   - **Windows Server 2022 Standard Evaluation (Desktop Experience)**
5. Accept license terms
6. Installation type: **Custom**
7. Select the disk and continue
8. Complete installation
9. Set the local **Administrator** password
10. Log in to the server

---

## Step 3: Rename the Server

1. Open **Server Manager**
2. Navigate to **Local Server**
3. Click the computer name
4. Rename the server to:
`
DC01
`
5. Restart when prompted

---

## Step 4: Configure Static IP and DNS

1. Open **Network and Sharing Center**
2. Click **Change adapter settings**
3. Right-click **Ethernet → Properties**
4. Select **Internet Protocol Version 4 (IPv4)** → Properties
5. Configure:
`
IP Address: 192.168.10.10
Subnet Mask: 255.255.255.0
Default Gateway: (leave blank)
Preferred DNS: 192.168.10.10
`
6. Save settings

---

## Automated Phase – Domain Promotion & Baseline

From this point onward, **PowerShell scripts are used** to perform Domain Controller promotion and baseline configuration.

This approach mirrors how identity teams operate in real enterprise environments.

---

## Step 5: Prepare for Script Execution

### Prerequisites Checklist

Ensure the following before proceeding:

- Server name is `DC01`
- Static IP is configured
- DNS points to `192.168.10.10`
- Logged in as **local Administrator**
- PowerShell is launched **as Administrator**
- Scripts are copied to:
`
C:\scripts
`

---

## Step 6: Install AD DS and Promote Domain Controller

Run the following script:

`
.\01-InstallAndPromote-DC.ps1
` 

### What This Script Does

- Installs Active Directory Domain Services
- Installs DNS Server role
- Promotes the server to a Domain Controller
- Creates the iamlab.local forest
- Triggers an automatic reboot

> ⏳ The server will reboot automatically once promotion completes.

---

## Step 7: Post-Reboot Validation

After the automatic reboot, log in using the domain administrator account:
`
IAMLAB\Administrator
`

Ensure you are logged in successfully and the desktop loads without errors.

---

### Run Post-Reboot Validation Script

Open **PowerShell as Administrator** and navigate to the scripts directory:
`
cd C:\scripts
`
Execute the validation script:
`
.\02-PostReboot-Validate-DC.ps1
`
### What This Script Validates

- Active Directory Domain Services status
- Domain availability and health
- DNS service availability
- FSMO role placement
- Basic DC operational readiness
This script confirms the Domain Controller is functional before applying any baseline configuration.

---

## Step 8: Apply Generic Active Directory Baseline

Once validation completes successfully, apply the baseline Active Directory configuration.

Run the following script:
`
.\03-AD-Baseline-Generic.ps1
`
### What This Script Configures

- Core Organizational Unit (OU) structure
- Baseline security groups
- Containers for service and non-human identities
- Initial administrative group structure

This baseline intentionally reflects common enterprise starting states, not best-practice perfection.

---

## ⚠️Intentional Gaps (By Design)

The following are intentionally not implemented at this stage:

Tiered administration model
Privileged Access Management tooling
Credential rotation or vaulting
Security monitoring and alerting

These gaps will be addressed in later phases of the lab.

---

## ✅ Phase 1 Exit Criteria

You should now have:

- DC01 running successfully
- Active Directory domain iamlab.local
- AD DS and DNS roles installed
- Baseline OU and group structure created
- Validation script executed without errors

Meeting these criteria confirms Phase 1 is complete.

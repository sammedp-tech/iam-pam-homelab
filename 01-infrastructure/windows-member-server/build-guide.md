# Phase 2 – Windows Member Server Build

This phase introduces a **Windows member server** and intentionally creates
**privileged access anti-patterns** commonly seen in enterprise environments.

This server will be used to demonstrate:
- Local administrator sprawl
- Service account misuse
- Privilege dependency on domain credentials

---

## 🧠 Purpose of This Phase

You will:
- Build a Windows Server 2022 member server
- Join it to the Active Directory domain
- Introduce local administrator privilege issues
- Prepare the system for PAM-related use cases

---

## Beginner Track – Manual Foundation

### VM Configuration

| Setting | Value |
|------|------|
| VM Name | SRV01 |
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
7. Name the VM: `SRV01`
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
3. Rename the server to:
`
SRV01
`

4. Restart when prompted

---

## Step 4: Configure Static IP

1. Open **Network and Sharing Center**
2. Click **Change adapter settings**
3. Right-click **Ethernet → Properties**
4. Select **Internet Protocol Version 4 (IPv4)** → Properties
5. Configure:
`
IP Address: 192.168.10.20; 
Subnet Mask: 255.255.255.0; 
Default Gateway: (leave blank); 
Preferred DNS: 192.168.10.10
`

7. Save settings

---

## Step 5: Join Server to Active Directory Domain

1. Open **Server Manager**
2. Navigate to **Local Server**
3. Click **Workgroup**
4. Select **Change**
5. Choose **Domain**
6. Enter:
`
iamlab.local
`

7. Provide domain Administrator credentials
8. Restart when prompted

---

## Automated Phase – Privilege Baseline Setup

From this point onward, **scripts are used** to introduce realistic privilege configurations.

---

## Step 6: Prepare for Script Execution

### Prerequisites Checklist

Ensure:
- Server name is `SRV01`
- Domain join is successful
- DNS points to DC01
- Logged in as **domain Administrator**
- PowerShell is run **as Administrator**
- Scripts are available in:
`
C:\scripts
`

---

## Step 7: Pre-Boot Domain Join

Run the pre-boot domain join script:

```powershell
.\04a-PreBoot-JoinDomain.ps1
```
What This Script Does

- Joins SRV01 to the iamlab.local domain
- Uses domain credentials securely
- Triggers a system reboot

⏳ The server will reboot automatically after the domain join.

---

## Step 8: Post-Boot Server Configuration

After reboot, log in using domain credentials:
`IAMLAB\Administrator`
Run the post-boot configuration script:
```powershell
.\04b-PostBoot-ServerConfig.ps1
```
### What This Script Does

- Validates successful domain join
- Applies basic server configuration
- Prepares the server for future IAM and PAM use cases

---

## Consultant Notes – Why This Separation Matters

- Domain onboarding and privilege management are separate lifecycle stages
- Mixing domain join with privilege configuration creates long-term risk
- Clean separation enables safer automation and rollback
- This mirrors mature enterprise operating models

Most environments fail precisely because these steps are combined.

---
## You should now have:

- SRV01 joined to the domain
- Multiple domain users with local admin rights
- A service account with persistent privileges
- Scheduled task running under static credentials

This server is now ready for **controlled privilege expansion**.

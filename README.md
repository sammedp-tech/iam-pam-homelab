# 🧾 IAM & PAM Home Lab

This repository helps you build a **fully functional Identity and Privileged Access Management (IAM & PAM) home lab** on your personal machine using Windows and Linux virtual machines.

You will recreate **real-world identity and privilege issues** commonly seen in enterprise environments, understand the risks they introduce, and learn how they are typically remediated.

---

## Who This Is For

- Beginners starting their journey in IAM or PAM
- IAM / PAM consultants and security engineers
- Anyone preparing for hands-on interviews or PoCs

## What You’ll Build

- Windows Active Directory domain
- Windows member server with privileged access challenges
- Linux server with sudo and SSH misconfigurations
- Service and non-human identities with static credentials

### Estimated setup time: 2–4 hours

---

## What This Is Not

❌ Production-ready infrastructure

❌ Vendor-specific training

❌ Cloud IAM or Zero Trust lab

---

## Technology Stack

- VMware Workstation Pro (recommended)
- Windows Server 2022 (Evaluation)
- Ubuntu Server 22.04 LTS

---

## Phases 

### Phase 0 – Lab Bootstrap
- VMware
- ISOs
- Networking
  
Focus on 00-Pre-requisites & 01-Infrastructure.

### Phase 1 – Identity Authority (AD as Control Plane)
-  **AD** as identity source
- DC build (scripted)
- Minimal OU + users

### Phase 2 – Privilege Surfaces (Where PAM Lives)
- Windows member server
- Local admin group
- Domain trust assumptions

### Phase 3 – Non-Human Identities
- Service accounts
- Scheduled tasks
- Credential persistence

### Phase 4 – Control & Remediation
- Least privilege
- Credential Rotation
- Just-in-time
- Auditability

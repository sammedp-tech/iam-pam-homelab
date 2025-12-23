# VMware Workstation Pro Setup

This lab uses **VMware Workstation Pro** as the recommended hypervisor.

## Why VMware Workstation Pro

- Free for personal use
- Stable host-only networking
- Widely used in enterprise environments
- Excellent Windows and Linux guest support

> VMware Workstation Pro is recommended.  
> VirtualBox can be used with minor networking adjustments.

---

## Installation

1. Download VMware Workstation Pro from the official VMware website
2. Run the installer
3. Use default installation settings
4. Reboot the system if prompted

---

## Networking Model

The lab uses **Host-Only Networking** to:

- Isolate the lab from your home network
- Avoid IP conflicts
- Simulate internal enterprise networks
- Keep the setup simple and predictable

---

## Create Host-Only Network (VMnet10)

1. Open **VMware Workstation**
2. Go to **Edit → Virtual Network Editor**
3. Click **Add Network**
4. Select **VMnet10**
5. Set the network type to **Host-only**
6. Disable **DHCP**
7. Apply and save changes

> All lab virtual machines must be connected to **VMnet10**

---

## Recommended Host Folder Structure

Create a dedicated folder on your host machine:

```
D:\iam-pam-homelab
├── isos
├── vms\
```

- Store all ISO files in the `isos` folder
- Store all virtual machines in the `vms` folder

This makes backups, cleanup, and resets much easier.

---

## Important Notes

- Do **not** bridge VMs to your physical network
- Do **not** expose lab VMs to the internet
- Static IPs will be configured later in the lab

The goal is a controlled and isolated identity environment.

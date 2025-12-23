<#
.DISCLAMER

This project is designed to help users "learn IAM and PAM concepts through hands-on labs".

The PowerShell scripts provided here are **not production-hardened** and should be treated as reference implementations only.
Before running any script:
- Read and understand the script logic
- Validate it in a test or lab environment
- Modify it to suit your infrastructure and security requirements

The author provides these scripts "without any warranty" and is not liable for any consequences resulting from their use.
If you are unsure about a script’s impact, **do not run it**.

.DEVELOPEDBY
Sammed Patil

.SYNOPSIS
Pre-reboot script: installs AD DS role and promotes this server 
to a new forest/domain controller.

It will:
- Ask for the domain name (e.g. lab.local)
- Derive NetBIOS name from domain
- Ask for DSRM (Safe Mode) password
- Install AD DS role
- Promote to Domain Controller (new forest)
- Trigger reboot automatically
#>

# Ensure script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Error "You must run this script in an elevated PowerShell session (Run as Administrator)."
    exit 1
}

Write-Host "=== Domain Controller Setup: PRE-REBOOT Script ===" -ForegroundColor Cyan

# Ask for domain name
$domainName = Read-Host "Enter the FQDN of the new domain (e.g. lab.local)"

if ([string]::IsNullOrWhiteSpace($domainName)) {
    Write-Error "Domain name cannot be empty. Exiting."
    exit 1
}

# Derive NetBIOS name (leftmost label, uppercase, max 15 chars)
$netbiosName = $domainName.Split('.')[0].ToUpper()
if ($netbiosName.Length -gt 15) {
    $netbiosName = $netbiosName.Substring(0, 15)
}

Write-Host "Using NetBIOS name: $netbiosName" -ForegroundColor Yellow

# Ask for DSRM (Directory Services Restore Mode) password
Write-Host "Set the DSRM (Safe Mode) password. This is NOT your domain admin password." -ForegroundColor Yellow
$dsrmPassword1 = Read-Host "Enter DSRM password" -AsSecureString
$dsrmPassword2 = Read-Host "Confirm DSRM password" -AsSecureString

if (([Runtime.InteropServices.Marshal]::PtrToStringUni(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($dsrmPassword1))) -ne
    ([Runtime.InteropServices.Marshal]::PtrToStringUni(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($dsrmPassword2)))) {
    Write-Error "Passwords do not match. Exiting."
    exit 1
}

Write-Host "Installing Active Directory Domain Services role..." -ForegroundColor Cyan

# Install AD DS role
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools -ErrorAction Stop

Write-Host "AD DS role installed successfully." -ForegroundColor Green
Write-Host "Promoting this server to a domain controller for new forest: $domainName" -ForegroundColor Cyan

# Promote to domain controller (new forest)
Import-Module ADDSDeployment

Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetbiosName $netbiosName `
    -SafeModeAdministratorPassword $dsrmPassword1 `
    -InstallDNS:$true `
    -Force:$true `
    -NoRebootOnCompletion:$false

# Note: -NoRebootOnCompletion:$false means it will reboot automatically after promotion.
# Once it reboots, log in as: DOMAIN\Administrator


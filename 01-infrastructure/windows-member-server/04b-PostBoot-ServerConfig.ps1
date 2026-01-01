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
Post-boot script: run AFTER the server is domain-joined.

- Detects current AD domain
- Asks which domain groups should get local admin:
  - Tier-0 group (default: GRP-LAB-Tier0-Admins)
  - Server admin group (default: GRP-LAB-Server-Admins)
- Always includes Domain Admins
- Enables Remote Desktop and firewall rule
#>

# Ensure elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Error "Run this script as Administrator."
    exit 1
}

Write-Host "=== POST-BOOT: SERVER CONFIG SCRIPT ===" -ForegroundColor Cyan

# Detect domain
try {
    $adDomain      = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $domainDns     = $adDomain.Name
    $domainNetbios = $adDomain.NetBiosName

    Write-Host "Current AD Domain DNS Name : $domainDns" -ForegroundColor Green
    Write-Host "Current AD Domain NetBIOS  : $domainNetbios" -ForegroundColor Green
}
catch {
    Write-Error "Cannot detect AD domain. Are you sure this server is domain-joined and rebooted?"
    exit 1
}

# Ask for groups
$defaultTier0Group   = "GRP-LAB-Tier0-Admins"
$defaultServerAdmins = "GRP-LAB-Server-Admins"

Write-Host "`nConfigure which domain groups get local admin on THIS SERVER..." -ForegroundColor Cyan

$tier0Input = Read-Host "Tier-0 group (default: $defaultTier0Group)"
if ([string]::IsNullOrWhiteSpace($tier0Input)) { $tier0Group = $defaultTier0Group } else { $tier0Group = $tier0Input }

$serverAdminsInput = Read-Host "Server-admin group (default: $defaultServerAdmins)"
if ([string]::IsNullOrWhiteSpace($serverAdminsInput)) { $serverAdminGroup = $defaultServerAdmins } else { $serverAdminGroup = $serverAdminsInput }

$domainAdminsFull = "$domainNetbios\Domain Admins"
$tier0GroupFull   = "$domainNetbios\$tier0Group"
$serverAdminsFull = "$domainNetbios\$serverAdminGroup"

Write-Host "`nWill add to local Administrators:" -ForegroundColor Yellow
Write-Host " - $domainAdminsFull" -ForegroundColor Yellow
Write-Host " - $tier0GroupFull"   -ForegroundColor Yellow
Write-Host " - $serverAdminsFull" -ForegroundColor Yellow

# 1) Enable Remote Desktop
Write-Host "`n[1/2] Enabling Remote Desktop + firewall rules..." -ForegroundColor Cyan

try {
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
        -Name "fDenyTSConnections" -Value 0

    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" | Out-Null

    Write-Host "Remote Desktop enabled and firewall rules configured." -ForegroundColor Green
}
catch {
    Write-Warning "Failed to enable RDP: $($_.Exception.Message)"
}

# 2) Add domain groups to local Administrators
Write-Host "`n[2/2] Adjusting local Administrators membership..." -ForegroundColor Cyan

$localAdminsGroup = "Administrators"
$membersToAdd     = @($domainAdminsFull, $tier0GroupFull, $serverAdminsFull)

$useLocalGroupCmdlet = Get-Command Add-LocalGroupMember -ErrorAction SilentlyContinue

foreach ($member in $membersToAdd) {
    try {
        if ($useLocalGroupCmdlet) {
            Add-LocalGroupMember -Group $localAdminsGroup -Member $member -ErrorAction Stop
        } else {
            & net localgroup $localAdminsGroup "$member" /add | Out-Null
        }
        Write-Host "Added to local Administrators: $member" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to add $member to local Administrators: $($_.Exception.Message)"
    }
}

Write-Host "`n=== POST-BOOT SERVER CONFIG COMPLETE ===" -ForegroundColor Cyan
Write-Host "Use domain admin accounts (e.g. $domainNetbios\\<your-admin>) for managing this server." -ForegroundColor Green

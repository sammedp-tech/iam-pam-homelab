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
Generic AD baseline setup script.

Asks for:
- Domain name (for domain-DN resolution)
- Top-level OU
- Admin username + display name + password
- Standard username + display name + password

Creates:
- LAB OU tree (tier0/servers/workstations/groups/identities)
- Privileged groups
- Standard groups
- Admin and Standard users

This script is fully generic and reusable across any environment.
#>

# Ensure admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Error "Run this script in an elevated PowerShell session (Run as Administrator)."
    exit 1
}

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "=== GENERIC AD BASELINE SETUP ===" -ForegroundColor Cyan

# -----------------------------
#  DOMAIN INPUT
# -----------------------------
$domainName = Read-Host "Enter the Domain Name (e.g., example.local)"
if ([string]::IsNullOrWhiteSpace($domainName)) {
    Write-Error "Domain name cannot be empty."
    exit 1
}

try {
    $domain = Get-ADDomain -Identity $domainName
}
catch {
    Write-Error "Domain $domainName not found. Make sure you're running this on a promoted DC."
    exit 1
}

$domainDN = $domain.DistinguishedName
$dnsRoot  = $domain.DNSRoot

Write-Host "Domain detected: $dnsRoot ($domainDN)" -ForegroundColor Green

# -----------------------------
#  OU INPUT
# -----------------------------
$baseOUName = Read-Host "Enter top-level OU (Default: LAB)"
if ([string]::IsNullOrWhiteSpace($baseOUName)) { $baseOUName = "LAB" }

$baseOUDN = "OU=$baseOUName,$domainDN"

# -----------------------------
#  USER INPUTS
# -----------------------------

# Admin
$adminSam = Read-Host "Enter ADMIN username (e.g., admin.sam)"
$adminDisplay = Read-Host "Enter ADMIN display name (e.g., Sam Admin)"
Write-Host "Enter ADMIN account password:" -ForegroundColor Yellow
$adminPwd1 = Read-Host "Password" -AsSecureString
$adminPwd2 = Read-Host "Confirm Password" -AsSecureString

if (([Runtime.InteropServices.Marshal]::PtrToStringUni(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPwd1))) -ne
    ([Runtime.InteropServices.Marshal]::PtrToStringUni(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPwd2)))) {
    Write-Error "Admin passwords do not match."
    exit 1
}

$adminUPN = "$adminSam@$dnsRoot"

# Standard user
$stdSam = Read-Host "Enter STANDARD username (e.g., user01)"
$stdDisplay = Read-Host "Enter STANDARD display name (e.g., John User)"
Write-Host "Enter STANDARD account password:" -ForegroundColor Yellow
$stdPwd1 = Read-Host "Password" -AsSecureString
$stdPwd2 = Read-Host "Confirm Password" -AsSecureString

if (([Runtime.InteropServices.Marshal]::PtrToStringUni(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($stdPwd1))) -ne
    ([Runtime.InteropServices.Marshal]::PtrToStringUni(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($stdPwd2)))) {
    Write-Error "Standard user passwords do not match."
    exit 1
}

$stdUPN = "$stdSam@$dnsRoot"

# -----------------------------
#  HELPER FUNCTIONS
# -----------------------------
function New-LabOU {
    param(
        [string]$Name,
        [string]$ParentDN
    )
    $ouDN = "OU=$Name,$ParentDN"
    if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$ouDN)" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Name -Path $ParentDN -ProtectedFromAccidentalDeletion $true | Out-Null
        Write-Host "Created OU: $ouDN" -ForegroundColor Green
    }
    return $ouDN
}

function New-LabGroup {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Description = ""
    )
    if (-not (Get-ADGroup -Filter "SamAccountName -eq '$Name'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $Name -SamAccountName $Name -GroupScope Global -GroupCategory Security `
        -Path $Path -Description $Description | Out-Null
        Write-Host "Created Group: $Name" -ForegroundColor Green
    }
}

# -----------------------------
#  OU STRUCTURE CREATION
# -----------------------------
Write-Host "`n=== Creating OU Structure ===" -ForegroundColor Cyan

New-LabOU -Name $baseOUName -ParentDN $domainDN

$ouTier0        = New-LabOU -Name "Tier-0"               -ParentDN $baseOUDN
$ouDCs          = New-LabOU -Name "Domain Controllers"   -ParentDN $ouTier0
$ouAdminServers = New-LabOU -Name "Admin Servers"        -ParentDN $ouTier0
$ouPAM          = New-LabOU -Name "PAM"                  -ParentDN $ouTier0

$ouServers      = New-LabOU -Name "Servers"              -ParentDN $baseOUDN
New-LabOU -Name "Infrastructure" -ParentDN $ouServers
New-LabOU -Name "Application"    -ParentDN $ouServers

$ouWorkstations = New-LabOU -Name "Workstations"         -ParentDN $baseOUDN
New-LabOU -Name "Admin Workstations" -ParentDN $ouWorkstations
New-LabOU -Name "User Workstations"  -ParentDN $ouWorkstations

$ouIdentities   = New-LabOU -Name "Identities"           -ParentDN $baseOUDN
$ouAdmins       = New-LabOU -Name "Admins"               -ParentDN $ouIdentities
$ouUsers        = New-LabOU -Name "Users"                -ParentDN $ouIdentities
$ouSvcAccounts  = New-LabOU -Name "Service Accounts"     -ParentDN $ouIdentities

$ouGroups       = New-LabOU -Name "Groups"               -ParentDN $baseOUDN
$ouPrivGroups   = New-LabOU -Name "Privileged"           -ParentDN $ouGroups
$ouRoleGroups   = New-LabOU -Name "Roles"                -ParentDN $ouGroups
$ouAppGroups    = New-LabOU -Name "Applications"         -ParentDN $ouGroups

# -----------------------------
#  GROUP CREATION
# -----------------------------
Write-Host "`n=== Creating Baseline Groups ===" -ForegroundColor Cyan

New-LabGroup -Name "GRP-LAB-Tier0-Admins"       -Path $ouPrivGroups -Description "Tier-0 Admins"
New-LabGroup -Name "GRP-LAB-Server-Admins"      -Path $ouPrivGroups
New-LabGroup -Name "GRP-LAB-Workstation-Admins" -Path $ouPrivGroups
New-LabGroup -Name "GRP-LAB-Helpdesk"           -Path $ouPrivGroups
New-LabGroup -Name "GRP-LAB-PAM-Admins"         -Path $ouPrivGroups

New-LabGroup -Name "GRP-LAB-Standard-Users"     -Path $ouRoleGroups

# -----------------------------
#  ADMIN USER CREATION
# -----------------------------
Write-Host "`n=== Creating Admin Account: $adminSam ===" -ForegroundColor Cyan

New-ADUser `
    -Name $adminDisplay `
    -GivenName $adminDisplay `
    -SamAccountName $adminSam `
    -UserPrincipalName $adminUPN `
    -Path $ouAdmins `
    -AccountPassword $adminPwd1 `
    -Enabled $true `
    -PasswordNeverExpires $true `
    -Description "LAB Admin account"

$adminGroups = @(
    "Domain Admins",
    "Enterprise Admins",
    "GRP-LAB-Tier0-Admins",
    "GRP-LAB-Server-Admins",
    "GRP-LAB-Workstation-Admins",
    "GRP-LAB-PAM-Admins"
)

foreach ($grp in $adminGroups) {
    Add-ADGroupMember -Identity $grp -Members $adminSam -ErrorAction SilentlyContinue
}

# -----------------------------
#  STANDARD USER CREATION
# -----------------------------
Write-Host "`n=== Creating Standard User: $stdSam ===" -ForegroundColor Cyan

New-ADUser `
    -Name $stdDisplay `
    -GivenName $stdDisplay `
    -SamAccountName $stdSam `
    -UserPrincipalName $stdUPN `
    -Path $ouUsers `
    -AccountPassword $stdPwd1 `
    -Enabled $true `
    -ChangePasswordAtLogon $true `
    -Description "LAB Standard User"

Add-ADGroupMember -Identity "GRP-LAB-Standard-Users" -Members $stdSam

Write-Host "`n=== SCRIPT COMPLETE ===" -ForegroundColor Green
Write-Host "Admin Account: $adminUPN"
Write-Host "Standard User: $stdUPN"
Write-Host "Top-level OU: $baseOUName"

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
Pre-boot script: join this server to a domain (generic).

- Asks for:
  - Target domain name
  - New computer name (optional)
  - Domain join account (user@domain or DOMAIN\user)
  - OU path (optional)
  - Whether to auto-reboot

Run as: local Administrator on the server before/while joining domain.
#>

# Ensure elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Error "Run this script as Administrator."
    exit 1
}

Write-Host "=== PRE-BOOT: DOMAIN JOIN SCRIPT ===" -ForegroundColor Cyan

# Current system info
$cs = Get-CimInstance Win32_ComputerSystem
$currentName   = $cs.Name
$partOfDomain  = [bool]$cs.PartOfDomain
$currentDomain = $cs.Domain

Write-Host "Current computer name : $currentName" -ForegroundColor Yellow
Write-Host "Currently part of domain? $partOfDomain" -ForegroundColor Yellow
if ($partOfDomain) {
    Write-Host "Current domain        : $currentDomain" -ForegroundColor Yellow
}

# Target domain
$targetDomain = Read-Host "Enter TARGET domain name (e.g. sammedp-tech.com)"
if ([string]::IsNullOrWhiteSpace($targetDomain)) {
    Write-Error "Domain name cannot be empty."
    exit 1
}

# Decide if we actually need to join
if ($partOfDomain -and ($currentDomain -ieq $targetDomain)) {
    Write-Host "This server is already joined to $targetDomain." -ForegroundColor Green
    Write-Host "Use the POST-BOOT script for configuration." -ForegroundColor Yellow
    exit 0
}
elseif ($partOfDomain -and ($currentDomain -ine $targetDomain)) {
    Write-Error "Server is already joined to a different domain: $currentDomain. Disjoin first."
    exit 1
}

# New name (optional)
$newNameInput = Read-Host "Enter NEW computer name for domain (press Enter to keep '$currentName')"
if ([string]::IsNullOrWhiteSpace($newNameInput)) {
    $newName = $currentName
} else {
    $newName = $newNameInput
}

# Credentials
Write-Host "`nEnter an account with rights to join computers to the domain." -ForegroundColor Yellow
Write-Host "Format: DOMAIN\\user or user@domain" -ForegroundColor Yellow
$joinUser = Read-Host "Domain join account"
if ([string]::IsNullOrWhiteSpace($joinUser)) {
    Write-Error "Join account cannot be empty."
    exit 1
}
$joinPassword = Read-Host "Password for $joinUser" -AsSecureString
$cred = New-Object System.Management.Automation.PSCredential($joinUser, $joinPassword)

# Optional OU
Write-Host "`nOPTIONAL: Enter OU distinguishedName to place this server into." -ForegroundColor Yellow
Write-Host "Example: OU=Infrastructure,OU=Servers,OU=LAB,DC=sammedp-tech,DC=com" -ForegroundColor Yellow
$ouPath = Read-Host "Leave blank to use default Computers container"

# Reboot choice
$rebootAnswer = Read-Host "Restart automatically after successful domain join? (Y/N, default: Y)"
if ([string]::IsNullOrWhiteSpace($rebootAnswer) -or $rebootAnswer -match '^[Yy]$') {
    $doReboot = $true
} else {
    $doReboot = $false
}

# Domain join
try {
    Write-Host "`nJoining domain '$targetDomain' as '$newName'..." -ForegroundColor Cyan

    $params = @{
        DomainName  = $targetDomain
        Credential  = $cred
        NewName     = $newName
        Force       = $true
        ErrorAction = 'Stop'
    }

    if (-not [string]::IsNullOrWhiteSpace($ouPath)) {
        $params["OUPath"] = $ouPath
    }

    Add-Computer @params

    Write-Host "Successfully joined $targetDomain as $newName." -ForegroundColor Green

    if ($doReboot) {
        Write-Host "Restarting now to complete domain join..." -ForegroundColor Cyan
        Restart-Computer -Force
        exit 0
    } else {
        Write-Host "Domain join complete. You MUST reboot manually before running POST-BOOT script." -ForegroundColor Yellow
        exit 0
    }
}
catch {
    Write-Error "Domain join FAILED: $($_.Exception.Message)"
    exit 1
}

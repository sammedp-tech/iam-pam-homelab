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
Post-reboot script: run after DC promotion.

It will:
- Confirm AD is available
- Run basic domain controller health checks
- Optionally configure a DNS forwarder (e.g. 8.8.8.8)
#>

# Ensure script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Error "You must run this script in an elevated PowerShell session (Run as Administrator)."
    exit 1
}

Write-Host "=== Domain Controller: POST-REBOOT Validation Script ===" -ForegroundColor Cyan

# Try to import Active Directory module
try {
    Import-Module ActiveDirectory -ErrorAction Stop
}
catch {
    Write-Error "Could not import ActiveDirectory module. Ensure RSAT/AD DS tools are installed."
    exit 1
}

# Get domain info
try {
    $domain = Get-ADDomain
    Write-Host "Domain detected: $($domain.DNSRoot)" -ForegroundColor Green
    Write-Host "Forest: $((Get-ADForest).Name)" -ForegroundColor Green
}
catch {
    Write-Error "Unable to query Active Directory domain. Something may be wrong with the promotion."
    exit 1
}

# Run basic dcdiag and save output
$logPath = "C:\Logs"
if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory | Out-Null
}

$dcDiagFile = Join-Path $logPath "dcdiag_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "Running dcdiag, this may take a moment..." -ForegroundColor Cyan
dcdiag /v | Out-File -FilePath $dcDiagFile -Encoding UTF8

Write-Host "dcdiag output saved to: $dcDiagFile" -ForegroundColor Green

# Optional: Configure DNS forwarder
Write-Host ""
Write-Host "Do you want to configure a DNS forwarder (e.g. 8.8.8.8) for internet name resolution?" -ForegroundColor Yellow
$configureForwarder = Read-Host "Type Y to configure a forwarder, anything else to skip"

if ($configureForwarder -match '^[Yy]$') {
    $forwarderIP = Read-Host "Enter DNS forwarder IP (e.g. 8.8.8.8)"

    if ([System.Net.IPAddress]::TryParse($forwarderIP, [ref]([System.Net.IPAddress]::Any))) {
        Write-Host "Configuring DNS forwarder: $forwarderIP" -ForegroundColor Cyan
        Add-DnsServerForwarder -IPAddress $forwarderIP -ErrorAction Stop
        Write-Host "DNS forwarder configured successfully." -ForegroundColor Green
    }
    else {
        Write-Error "Invalid IP address format. Skipping DNS forwarder configuration."
    }
}
else {
    Write-Host "Skipping DNS forwarder configuration." -ForegroundColor Yellow
}

# Final summary
Write-Host ""
Write-Host "=== Validation Summary ===" -ForegroundColor Cyan
Write-Host " - Domain: $($domain.DNSRoot)" -ForegroundColor Green
Write-Host " - dcdiag log: $dcDiagFile" -ForegroundColor Green
Write-Host "Post-reboot checks complete." -ForegroundColor Cyan


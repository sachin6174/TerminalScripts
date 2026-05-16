# Prevent Windows from sleeping even when lid is closed
# This script configures power settings to keep the system awake

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "This script requires administrator privileges. Restarting as administrator..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs "-File `"$PSCommandPath`""
    exit
}

Write-Host "Configuring power settings to prevent sleep..." -ForegroundColor Green

# Set monitor timeout to never (0) on AC power
powercfg /change monitor-timeout-ac 0
Write-Host "✓ Monitor timeout on AC power: Never" -ForegroundColor Green

# Set monitor timeout to never (0) on battery
powercfg /change monitor-timeout-dc 0
Write-Host "✓ Monitor timeout on battery: Never" -ForegroundColor Green

# Set standby timeout to never (0) on AC power
powercfg /change standby-timeout-ac 0
Write-Host "✓ Standby timeout on AC power: Never" -ForegroundColor Green

# Set standby timeout to never (0) on battery
powercfg /change standby-timeout-dc 0
Write-Host "✓ Standby timeout on battery: Never" -ForegroundColor Green

# Set hibernation timeout to never (0) on AC power
powercfg /change hibernate-timeout-ac 0
Write-Host "✓ Hibernation timeout on AC power: Never" -ForegroundColor Green

# Set hibernation timeout to never (0) on battery
powercfg /change hibernate-timeout-dc 0
Write-Host "✓ Hibernation timeout on battery: Never" -ForegroundColor Green

# Configure lid close action to do nothing
powercfg /setacvalueindex SCHEME_CURRENT 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
powercfg /setdcvalueindex SCHEME_CURRENT 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
Write-Host "✓ Lid close action: Do nothing" -ForegroundColor Green

# Apply the changes
powercfg /setactive SCHEME_CURRENT

Write-Host "`nPower settings configured successfully!" -ForegroundColor Green
Write-Host "Your device will now stay awake even when the lid is closed." -ForegroundColor Cyan
Write-Host "`nTo revert these changes, run the restore script or manually adjust power settings." -ForegroundColor Yellow
# Restore default Windows power settings
# This script reverts the changes made by prevent-sleep.ps1

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "This script requires administrator privileges. Restarting as administrator..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs "-File `"$PSCommandPath`""
    exit
}

Write-Host "Restoring default power settings..." -ForegroundColor Green

# Restore default monitor timeout (15 minutes on AC, 5 minutes on battery)
powercfg /change monitor-timeout-ac 15
powercfg /change monitor-timeout-dc 5
Write-Host "✓ Monitor timeout restored to defaults" -ForegroundColor Green

# Restore default standby timeout (30 minutes on AC, 15 minutes on battery)
powercfg /change standby-timeout-ac 30
powercfg /change standby-timeout-dc 15
Write-Host "✓ Standby timeout restored to defaults" -ForegroundColor Green

# Restore default hibernation timeout (3 hours on AC, 3 hours on battery)
powercfg /change hibernate-timeout-ac 180
powercfg /change hibernate-timeout-dc 180
Write-Host "✓ Hibernation timeout restored to defaults" -ForegroundColor Green

# Restore lid close action to sleep
powercfg /setacvalueindex SCHEME_CURRENT 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 1
powercfg /setdcvalueindex SCHEME_CURRENT 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 1
Write-Host "✓ Lid close action restored to sleep" -ForegroundColor Green

# Apply the changes
powercfg /setactive SCHEME_CURRENT

Write-Host "`nDefault power settings restored successfully!" -ForegroundColor Green
Write-Host "Your device will now follow normal sleep behavior." -ForegroundColor Cyan
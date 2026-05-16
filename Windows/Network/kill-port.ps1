<#
.SYNOPSIS
Finds and kills the process running on a specific port.
Domain: DevOps / Networking

.EXAMPLE
.\kill-port.ps1 -Port 3000
#>
param (
    [Parameter(Mandatory=$true)]
    [int]$Port
)

Write-Host "🔍 Searching for process on port $Port..." -ForegroundColor Cyan

$Connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue

if ($Connections) {
    $ProcessIds = $Connections.OwningProcess | Select-Object -Unique
    foreach ($Pid in $ProcessIds) {
        $Process = Get-Process -Id $Pid -ErrorAction SilentlyContinue
        if ($Process) {
            Write-Host "⚠️ Found Process '$($Process.ProcessName)' (PID: $Pid) on Port $Port" -ForegroundColor Yellow
            Stop-Process -Id $Pid -Force
            Write-Host "✅ Killed Process '$($Process.ProcessName)' (PID: $Pid)" -ForegroundColor Green
        }
    }
} else {
    Write-Host "✅ No process found running on port $Port." -ForegroundColor Green
}

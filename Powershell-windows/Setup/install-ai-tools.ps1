# Install AI Coding Tools for Windows
# This script installs various AI-powered coding tools and assistants

Write-Host "Installing AI Coding Tools..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
# curl https://cursor.com/install -fsS 
# Check if npm is installed
try {
    $npmVersion = npm --version
    Write-Host "✓ npm is installed (version: $npmVersion)" -ForegroundColor Green
} catch {
    Write-Host "✗ npm is not installed. Please install Node.js first." -ForegroundColor Red
    Write-Host "Download from: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Array of npm packages to install
$packages = @(
    "@qwen-code/qwen-code",
    "@anthropic-ai/claude-code", 
    "@openai/codex",
    "@google/gemini-cli",
    "cline",
    "@charmland/crush"
)

Write-Host "`nInstalling npm packages globally..." -ForegroundColor Yellow

foreach ($package in $packages) {
    Write-Host "Installing $package..." -ForegroundColor White
    try {
        npm install -g $package
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ $package installed successfully" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to install $package" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Error installing $package : $_" -ForegroundColor Red
    }
    Write-Host ""
}

# Install Cursor editor (Windows equivalent)
Write-Host "Installing Cursor editor..." -ForegroundColor Yellow

try {
    # Check if curl is available (Windows 10 1803+ has curl built-in)
    $curlVersion = curl --version 2>$null
    if ($curlVersion) {
        Write-Host "Using curl to download Cursor installer..." -ForegroundColor White
        
        # Download Cursor installer for Windows
        $cursorUrl = "https://downloader.cursor.sh/windows_x64/nsis"
        $installerPath = "$env:TEMP\cursor-installer.exe"
        
        curl -L $cursorUrl -o $installerPath
        
        if (Test-Path $installerPath) {
            Write-Host "✓ Cursor installer downloaded" -ForegroundColor Green
            Write-Host "Starting Cursor installation..." -ForegroundColor White
            Start-Process -FilePath $installerPath -Wait
            Remove-Item $installerPath -Force
            Write-Host "✓ Cursor installation completed" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to download Cursor installer" -ForegroundColor Red
        }
    } else {
        # Alternative method using Invoke-WebRequest
        Write-Host "Using PowerShell to download Cursor installer..." -ForegroundColor White
        $cursorUrl = "https://downloader.cursor.sh/windows_x64/nsis"
        $installerPath = "$env:TEMP\cursor-installer.exe"
        
        Invoke-WebRequest -Uri $cursorUrl -OutFile $installerPath
        
        if (Test-Path $installerPath) {
            Write-Host "✓ Cursor installer downloaded" -ForegroundColor Green
            Write-Host "Starting Cursor installation..." -ForegroundColor White
            Start-Process -FilePath $installerPath -Wait
            Remove-Item $installerPath -Force
            Write-Host "✓ Cursor installation completed" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to download Cursor installer" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "✗ Error installing Cursor: $_" -ForegroundColor Red
    Write-Host "You can manually download Cursor from: https://cursor.com/" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Installation Summary:" -ForegroundColor Green
Write-Host "- AI coding tools installed via npm" -ForegroundColor White
Write-Host "- Cursor editor downloaded and installed" -ForegroundColor White
Write-Host "`nNote: Some tools may require additional configuration or API keys." -ForegroundColor Yellow
Write-Host "Check each tool's documentation for setup instructions." -ForegroundColor Yellow
<#
.SYNOPSIS
Extracts all frames from a video file into a specified directory.

.EXAMPLE
.\extract-frames.ps1 -InputVideo "my_video.mp4" -OutputDir "frames_folder"
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Path to the input video file")]
    [string]$InputVideo,

    [Parameter(Mandatory=$false, HelpMessage="Directory to save the extracted frames")]
    [string]$OutputDir,

    [Parameter(Mandatory=$false, HelpMessage="Frames per second to extract. If omitted, extracts all frames.")]
    [string]$FPS
)

# Set default OutputDir to a timestamped folder on the Desktop if not provided
if (-not $OutputDir) {
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $OutputDir = Join-Path -Path $DesktopPath -ChildPath "extracted_frames_$Timestamp"
}

# Check if ffmpeg is available
if (!(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "⚙️  ffmpeg is not installed. Attempting to install via winget..." -ForegroundColor Yellow
    winget install "FFmpeg (Essentials Build)" -e --accept-package-agreements --accept-source-agreements
    
    # Reload environment variables to pick up ffmpeg path
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    if (!(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Failed to auto-install ffmpeg or it's still not in PATH. Please restart your terminal or install manually." -ForegroundColor Red
        exit
    }
    Write-Host "✅ ffmpeg installed successfully." -ForegroundColor Green
}

# Create output directory if it doesn't exist
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

if ($FPS) {
    Write-Host "⏳ Extracting $FPS frames per second from '$InputVideo' to '$OutputDir'..." -ForegroundColor Cyan
    # Uses the fps filter to extract specific amount of frames per second
    ffmpeg -i $InputVideo -vf "fps=$FPS" "$OutputDir\frame_%05d.png"
} else {
    Write-Host "⏳ Extracting ALL frames from '$InputVideo' to '$OutputDir'..." -ForegroundColor Cyan
    # -vsync 0 ensures exact original frames without dropping/duplicating (perfect for VFR)
    ffmpeg -i $InputVideo -vsync 0 "$OutputDir\frame_%05d.png"
}

Write-Host "✅ Extraction complete! Frames are saved in '$OutputDir\'" -ForegroundColor Green

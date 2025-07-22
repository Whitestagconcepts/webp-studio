# Install FFmpeg for WebP Maker on Windows
# Run this script as Administrator

Write-Host "Installing FFmpeg for WebP Maker..." -ForegroundColor Green

# Create FFmpeg directory
$ffmpegDir = "C:\ffmpeg"
if (!(Test-Path $ffmpegDir)) {
    New-Item -ItemType Directory -Path $ffmpegDir -Force
}

# Download FFmpeg
$ffmpegUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
$zipPath = "$env:TEMP\ffmpeg.zip"
$extractPath = "$env:TEMP\ffmpeg_extract"

Write-Host "Downloading FFmpeg..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $ffmpegUrl -OutFile $zipPath

Write-Host "Extracting FFmpeg..." -ForegroundColor Yellow
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

# Find the extracted FFmpeg folder (it has a version number in the name)
$ffmpegFolder = Get-ChildItem -Path $extractPath -Directory | Where-Object { $_.Name -like "ffmpeg-*" } | Select-Object -First 1

# Copy files to C:\ffmpeg
Copy-Item -Path "$($ffmpegFolder.FullName)\*" -Destination $ffmpegDir -Recurse -Force

# Add to PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
$ffmpegBinPath = "$ffmpegDir\bin"

if ($currentPath -notlike "*$ffmpegBinPath*") {
    Write-Host "Adding FFmpeg to system PATH..." -ForegroundColor Yellow
    $newPath = "$currentPath;$ffmpegBinPath"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, [EnvironmentVariableTarget]::Machine)
    
    # Also set for current session
    $env:PATH += ";$ffmpegBinPath"
}

# Clean up
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "FFmpeg installation completed!" -ForegroundColor Green
Write-Host "You may need to restart your applications to use FFmpeg." -ForegroundColor Yellow

# Test FFmpeg
Write-Host "Testing FFmpeg installation..." -ForegroundColor Cyan
try {
    & ffmpeg -version
    Write-Host "FFmpeg is working correctly!" -ForegroundColor Green
} catch {
    Write-Host "FFmpeg test failed. Please restart your terminal and try again." -ForegroundColor Red
} 
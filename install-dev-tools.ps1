# install-dev-tools.ps1
# One-click installer for all development tools needed for Claude Code web apps
# Works without winget - uses direct downloads
#
# Usage: Right-click this file → "Run with PowerShell"
# Or run: powershell -ExecutionPolicy Bypass -File install-dev-tools.ps1

$ErrorActionPreference = "Stop"
$downloadDir = "$env:TEMP\dev-tools-install"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Claude Code Development Tools Setup  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator. Some installations may fail." -ForegroundColor Yellow
    Write-Host "Consider right-clicking and selecting 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
}

# Create temp download directory
New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null

# Helper function to check if command exists
function Test-Command($command) {
    try {
        Get-Command $command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# ============================================
# 1. Node.js
# ============================================
Write-Host "[1/5] Checking Node.js..." -ForegroundColor Yellow

if (Test-Command "node") {
    $nodeVersion = node --version
    Write-Host "  Node.js already installed: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "  Downloading Node.js LTS..." -ForegroundColor White
    $nodeUrl = "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi"
    $nodeMsi = "$downloadDir\node.msi"

    try {
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeMsi -UseBasicParsing
        Write-Host "  Installing Node.js (this may take a minute)..." -ForegroundColor White
        Start-Process msiexec.exe -Wait -ArgumentList "/i `"$nodeMsi`" /quiet /norestart"
        Write-Host "  Node.js installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to install Node.js. Install manually from https://nodejs.org" -ForegroundColor Red
    }
}

# ============================================
# 2. Git
# ============================================
Write-Host ""
Write-Host "[2/5] Checking Git..." -ForegroundColor Yellow

if (Test-Command "git") {
    $gitVersion = git --version
    Write-Host "  Git already installed: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "  Downloading Git..." -ForegroundColor White
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"
    $gitExe = "$downloadDir\git-installer.exe"

    try {
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitExe -UseBasicParsing
        Write-Host "  Installing Git (this may take a minute)..." -ForegroundColor White
        Start-Process $gitExe -Wait -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS"
        Write-Host "  Git installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to install Git. Install manually from https://git-scm.com" -ForegroundColor Red
    }
}

# ============================================
# 3. Python (optional, for PDF processing)
# ============================================
Write-Host ""
Write-Host "[3/5] Checking Python..." -ForegroundColor Yellow

if (Test-Command "python") {
    $pythonVersion = python --version 2>&1
    Write-Host "  Python already installed: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "  Downloading Python..." -ForegroundColor White
    $pythonUrl = "https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe"
    $pythonExe = "$downloadDir\python-installer.exe"

    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonExe -UseBasicParsing
        Write-Host "  Installing Python (this may take a minute)..." -ForegroundColor White
        Start-Process $pythonExe -Wait -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"
        Write-Host "  Python installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to install Python. Install manually from https://python.org" -ForegroundColor Red
    }
}

# ============================================
# 4. Google Cloud SDK
# ============================================
Write-Host ""
Write-Host "[4/5] Checking Google Cloud SDK..." -ForegroundColor Yellow

if (Test-Command "gcloud") {
    $gcloudVersion = gcloud --version 2>&1 | Select-Object -First 1
    Write-Host "  Google Cloud SDK already installed: $gcloudVersion" -ForegroundColor Green
} else {
    Write-Host "  Downloading Google Cloud SDK..." -ForegroundColor White
    $gcloudUrl = "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe"
    $gcloudExe = "$downloadDir\gcloud-installer.exe"

    try {
        Invoke-WebRequest -Uri $gcloudUrl -OutFile $gcloudExe -UseBasicParsing
        Write-Host "  Installing Google Cloud SDK (this may take a minute)..." -ForegroundColor White
        Start-Process $gcloudExe -Wait -ArgumentList "/S"
        Write-Host "  Google Cloud SDK installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to install gcloud. Install manually from https://cloud.google.com/sdk" -ForegroundColor Red
    }
}

# ============================================
# 5. Claude Code (via npm)
# ============================================
Write-Host ""
Write-Host "[5/5] Installing Claude Code..." -ForegroundColor Yellow

# Refresh PATH to pick up newly installed tools
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

if (Test-Command "npm") {
    try {
        Write-Host "  Installing Claude Code globally via npm..." -ForegroundColor White
        npm install -g @anthropic-ai/claude-code 2>&1 | Out-Null
        Write-Host "  Claude Code installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to install Claude Code. Run manually: npm install -g @anthropic-ai/claude-code" -ForegroundColor Red
    }
} else {
    Write-Host "  SKIPPED: npm not found. Restart terminal and run: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
}

# ============================================
# Cleanup
# ============================================
Write-Host ""
Write-Host "Cleaning up temporary files..." -ForegroundColor White
Remove-Item -Recurse -Force $downloadDir -ErrorAction SilentlyContinue

# ============================================
# Summary
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Complete!               " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: Close this window and open a NEW terminal." -ForegroundColor Yellow
Write-Host ""
Write-Host "Then create a project folder and start Claude:" -ForegroundColor White
Write-Host "  mkdir C:\Projects\my-app" -ForegroundColor Gray
Write-Host "  cd C:\Projects\my-app" -ForegroundColor Gray
Write-Host "  claude" -ForegroundColor Gray
Write-Host ""
Write-Host "First time Claude runs, it will ask for your Anthropic login." -ForegroundColor White
Write-Host ""
Write-Host "For the full guide, visit: https://grick.me" -ForegroundColor Cyan
Write-Host ""

# Keep window open
Read-Host "Press Enter to close this window"

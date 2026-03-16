#Requires -Version 7
<#
.SYNOPSIS
    PowerShell Terminal Enhancement Suite - Setup Script
.DESCRIPTION
    Installs and configures: Oh My Posh, PSReadLine (ListView predictions),
    Terminal-Icons, PSFzf, PSCompletions, zoxide, bat, eza, fd, ripgrep,
    delta, btop, gsudo, lazygit, and a custom blue/purple prompt theme.
.NOTES
    Run in PowerShell 7+: irm <raw-url>/install.ps1 | iex
    Or clone and run: ./install.ps1
#>

param(
    [switch]$SkipScoop,
    [switch]$SkipModules,
    [switch]$SkipProfile,
    [switch]$SkipTheme
)

$ErrorActionPreference = 'Stop'
$repoUrl = "https://raw.githubusercontent.com/h34tsink/pwsh-setup/main"
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { "" }

function Write-Step { param($msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok { param($msg) Write-Host "   $msg" -ForegroundColor Green }
function Write-Skip { param($msg) Write-Host "   SKIP: $msg" -ForegroundColor Yellow }

# ── Scoop ──
if (-not $SkipScoop) {
    Write-Step "Installing Scoop package manager"
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-Expression "& {$(Invoke-RestMethod get.scoop.sh)} -RunAsAdmin"
        # Refresh PATH
        $env:PATH = "$HOME\scoop\shims;$env:PATH"
        Write-Ok "Scoop installed"
    } else {
        Write-Ok "Scoop already installed"
    }

    Write-Step "Adding Scoop buckets"
    $buckets = scoop bucket list | Select-Object -ExpandProperty Name
    if ($buckets -notcontains 'extras') { scoop bucket add extras }
    if ($buckets -notcontains 'main') { scoop bucket add main }
    Write-Ok "Buckets ready"

    Write-Step "Installing CLI tools via Scoop"
    $tools = @('bat', 'eza', 'fd', 'ripgrep', 'delta', 'btop', 'gsudo', 'lazygit', 'fzf', 'zoxide', 'gh', 'fastfetch')
    foreach ($tool in $tools) {
        if (Get-Command $tool -ErrorAction SilentlyContinue) {
            Write-Ok "$tool already installed"
        } else {
            Write-Host "   Installing $tool..." -ForegroundColor Gray
            scoop install $tool 2>$null
            Write-Ok "$tool installed"
        }
    }
} else {
    Write-Skip "Scoop and CLI tools"
}

# ── Oh My Posh ──
Write-Step "Installing Oh My Posh"
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
    Write-Ok "Oh My Posh installed"
} else {
    Write-Ok "Oh My Posh already installed ($(oh-my-posh --version))"
}

# ── PowerShell Modules ──
if (-not $SkipModules) {
    Write-Step "Installing PowerShell modules"
    $modules = @('Terminal-Icons', 'PSFzf', 'PSCompletions')
    foreach ($mod in $modules) {
        if (Get-Module -ListAvailable -Name $mod) {
            Write-Ok "$mod already installed"
        } else {
            Write-Host "   Installing $mod..." -ForegroundColor Gray
            Install-Module $mod -Scope CurrentUser -Force -SkipPublisherCheck
            Write-Ok "$mod installed"
        }
    }
} else {
    Write-Skip "PowerShell modules"
}

# ── Theme ──
if (-not $SkipTheme) {
    Write-Step "Installing custom prompt theme"
    $themesDir = "$HOME\.poshthemes"
    if (-not (Test-Path $themesDir)) { New-Item -ItemType Directory -Path $themesDir -Force | Out-Null }

    $themeSource = if ($scriptDir) { Join-Path $scriptDir "custom-blue.omp.json" } else { "" }
    if ($themeSource -and (Test-Path $themeSource)) {
        Copy-Item $themeSource "$themesDir\custom-blue.omp.json" -Force
    } else {
        Invoke-WebRequest -Uri "$repoUrl/custom-blue.omp.json" -OutFile "$themesDir\custom-blue.omp.json"
    }
    Write-Ok "Theme installed to $themesDir\custom-blue.omp.json"
} else {
    Write-Skip "Theme"
}

# ── Fastfetch Config ──
Write-Step "Installing fastfetch config"
$ffDir = "$HOME\.config\fastfetch"
if (-not (Test-Path $ffDir)) { New-Item -ItemType Directory -Path $ffDir -Force | Out-Null }

$ffConfigSource = if ($scriptDir) { Join-Path $scriptDir "fastfetch\config.jsonc" } else { "" }
if ($ffConfigSource -and (Test-Path $ffConfigSource)) {
    Copy-Item (Join-Path $scriptDir "fastfetch\config.jsonc") "$ffDir\config.jsonc" -Force
    Copy-Item (Join-Path $scriptDir "fastfetch\logo.txt") "$ffDir\logo.txt" -Force
} else {
    Invoke-WebRequest -Uri "$repoUrl/fastfetch/config.jsonc" -OutFile "$ffDir\config.jsonc"
    Invoke-WebRequest -Uri "$repoUrl/fastfetch/logo.txt" -OutFile "$ffDir\logo.txt"
}
Write-Ok "Fastfetch config installed to $ffDir"

# ── Profile ──
if (-not $SkipProfile) {
    Write-Step "Installing PowerShell profile"
    $profileDir = Split-Path $PROFILE
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }

    # Backup existing profile
    if (Test-Path $PROFILE) {
        $backup = "$PROFILE.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $PROFILE $backup
        Write-Ok "Existing profile backed up to $backup"
    }

    $profileSource = if ($scriptDir) { Join-Path $scriptDir "profile.ps1" } else { "" }
    if ($profileSource -and (Test-Path $profileSource)) {
        Copy-Item $profileSource $PROFILE -Force
    } else {
        Invoke-WebRequest -Uri "$repoUrl/profile.ps1" -OutFile $PROFILE
    }
    Write-Ok "Profile installed to $PROFILE"
} else {
    Write-Skip "Profile"
}

# ── Git config for delta ──
Write-Step "Configuring git to use delta"
$deltaConfig = if ($scriptDir) { Join-Path $scriptDir ".gitconfig-delta" } else { "" }
if (-not $deltaConfig -or -not (Test-Path $deltaConfig)) {
    $deltaConfig = "$env:TEMP\.gitconfig-delta"
    Invoke-WebRequest -Uri "$repoUrl/.gitconfig-delta" -OutFile $deltaConfig
}
if (Get-Command delta -ErrorAction SilentlyContinue) {
    git config --global core.pager "delta"
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.side-by-side true
    git config --global delta.line-numbers true
    git config --global delta.syntax-theme "Dracula"
    git config --global merge.conflictstyle "diff3"
    git config --global diff.colorMoved "default"
    Write-Ok "Git configured to use delta"
} else {
    Write-Skip "delta not found"
}

# ── Nerd Font reminder ──
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Make sure you have a Nerd Font installed:" -ForegroundColor Yellow
Write-Host "  https://www.nerdfonts.com/font-downloads" -ForegroundColor Gray
Write-Host "  Recommended: FiraCode Nerd Font or JetBrainsMono Nerd Font" -ForegroundColor Gray
Write-Host ""
Write-Host "  Restart your terminal to see changes." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Quick reference:" -ForegroundColor Cyan
Write-Host "    Ctrl+R  - Fuzzy history search (fzf)" -ForegroundColor White
Write-Host "    Ctrl+T  - Fuzzy file finder (fzf)" -ForegroundColor White
Write-Host "    Tab     - Menu/fzf completion" -ForegroundColor White
Write-Host "    lg      - lazygit" -ForegroundColor White
Write-Host "    ls/ll   - eza with icons" -ForegroundColor White
Write-Host "    lt      - eza tree view" -ForegroundColor White
Write-Host "    cat     - bat with syntax highlighting" -ForegroundColor White
Write-Host "    z <dir> - zoxide smart cd" -ForegroundColor White
Write-Host "    sudo    - gsudo elevate" -ForegroundColor White
Write-Host "    fastfetch - system info on startup" -ForegroundColor White
Write-Host ""

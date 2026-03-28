#Requires -Version 7
<#
.SYNOPSIS
    PowerShell Terminal Enhancement Suite - Setup Script
.DESCRIPTION
    Installs and configures: Git (with Git Bash), Oh My Posh, PSReadLine
    (ListView predictions), Terminal-Icons, PSFzf, PSCompletions, zoxide,
    bat, eza, fd, ripgrep, delta, btop, gsudo, lazygit, yazi,
    CaskaydiaCove Nerd Font Mono, and a custom blue/purple prompt theme.
.NOTES
    Run in PowerShell 7+: irm https://raw.githubusercontent.com/h34tsink/pwsh-setup/main/install.ps1 | iex
    Or clone and run: ./install.ps1
#>

param(
    [switch]$SkipScoop,
    [switch]$SkipFonts,
    [switch]$SkipOhMyPosh,
    [switch]$SkipModules,
    [switch]$SkipProfile,
    [switch]$SkipTheme,
    [switch]$SkipFastfetch,
    [switch]$SkipDelta,
    [switch]$SkipBtop
)

$ErrorActionPreference = 'Stop'
$repoUrl = "https://raw.githubusercontent.com/h34tsink/pwsh-setup/main"
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { "" }

# Ensure scoop shims are in PATH regardless of whether -SkipScoop is used
if ((Test-Path "$HOME\scoop\shims") -and ($env:PATH -notlike "*scoop\shims*")) {
    $env:PATH = "$HOME\scoop\shims;$env:PATH"
}

function Write-Step { param($msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok   { param($msg) Write-Host "   $msg" -ForegroundColor Green }
function Write-Skip { param($msg) Write-Host "   SKIP: $msg" -ForegroundColor Yellow }
function Write-Warn { param($msg) Write-Host "   WARN: $msg" -ForegroundColor DarkYellow }

# Map scoop package names to their actual binary names where they differ
$toolBinaryMap = @{
    'ripgrep'     = 'rg'
    'imagemagick' = 'magick'
    'poppler'     = 'pdftoppm'
}

function Get-ToolCommand {
    param([string]$tool)
    if ($toolBinaryMap.ContainsKey($tool)) { return $toolBinaryMap[$tool] }
    return $tool
}

# ── Scoop ──
if (-not $SkipScoop) {
    Write-Step "Installing Scoop package manager"
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
        } catch {
            # Ignore: policy may already be set or overridden at a more specific scope (e.g. -ExecutionPolicy Bypass passed at launch)
            Write-Warn "Set-ExecutionPolicy: $($_.Exception.Message.Split([System.Environment]::NewLine)[0])"
        }
        Invoke-Expression "& {$(Invoke-RestMethod get.scoop.sh)} -RunAsAdmin"
        $env:PATH = "$HOME\scoop\shims;$env:PATH"
        Write-Ok "Scoop installed"
    } else {
        Write-Ok "Scoop already installed"
    }

    Write-Step "Adding Scoop buckets"
    $buckets = scoop bucket list | Select-Object -ExpandProperty Name
    if ($buckets -notcontains 'extras')      { scoop bucket add extras }
    if ($buckets -notcontains 'main')        { scoop bucket add main }
    if ($buckets -notcontains 'nerd-fonts')  { scoop bucket add nerd-fonts }
    Write-Ok "Buckets ready"

    Write-Step "Installing CLI tools via Scoop"
    $tools = @('git', 'bat', 'eza', 'fd', 'ripgrep', 'delta', 'btop', 'gsudo', 'lazygit', 'fzf', 'zoxide', 'gh', 'fastfetch',
                'yazi', 'file', 'unar', 'imagemagick', 'poppler', 'ffmpeg')
    foreach ($tool in $tools) {
        $cmd = Get-ToolCommand $tool
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            Write-Ok "$tool already installed"
        } else {
            Write-Host "   Installing $tool..." -ForegroundColor Gray
            try {
                # Temporarily relax error handling — scoop manifest scripts (pre/post_install)
                # can throw non-fatal errors (e.g., btop's New-Item on existing config file)
                $prevEAP = $ErrorActionPreference
                $ErrorActionPreference = 'Continue'
                scoop install $tool
                $ErrorActionPreference = $prevEAP
                if ($LASTEXITCODE -ne 0) { Write-Warn "$tool install may have failed (exit code $LASTEXITCODE)" }
                else { Write-Ok "$tool installed" }
            } catch {
                $ErrorActionPreference = $prevEAP
                Write-Warn "$tool install encountered an error: $_"
            }
        }
    }

    # Refresh PATH so newly installed scoop shims (git, delta, etc.) are
    # immediately available for the rest of this script without a new session.
    $scoopShims = "$HOME\scoop\shims"
    if ((Test-Path $scoopShims) -and ($env:PATH -notlike "*scoop\shims*")) {
        $env:PATH = "$scoopShims;$env:PATH"
    }
} else {
    Write-Skip "Scoop and CLI tools"
}

# ── Fonts ──
if (-not $SkipFonts) {
    Write-Step "Installing CaskaydiaCove Nerd Font Mono (Cascadia Code)"
    $fontName = 'CascadiaCode-NF-Mono'
    $userFontsDir   = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $systemFontsDir = "$env:windir\Fonts"
    $installed = (Test-Path "$userFontsDir\CascadiaCodeNFM*") -or
                 (Test-Path "$systemFontsDir\CascadiaCodeNFM*")
    if ($installed) {
        Write-Ok "CascadiaCode Nerd Font Mono already installed"
    } else {
        # Ensure nerd-fonts bucket exists even if -SkipScoop was passed
        $buckets = scoop bucket list | Select-Object -ExpandProperty Name
        if ($buckets -notcontains 'nerd-fonts') {
            Write-Host "   Adding nerd-fonts bucket..." -ForegroundColor Gray
            scoop bucket add nerd-fonts
        }
        try {
            $prevEAP = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            scoop install $fontName
            $ErrorActionPreference = $prevEAP
            if ($LASTEXITCODE -ne 0) { Write-Warn "Font install may have failed (exit $LASTEXITCODE)" }
            else { Write-Ok "CascadiaCode Nerd Font Mono installed" }
        } catch {
            $ErrorActionPreference = $prevEAP
            Write-Warn "Font install encountered an error: $_"
        }
    }

    # Configure Windows Terminal to use the font
    # Use .NET to get the real LocalAppData path — $env:LOCALAPPDATA may be
    # overridden in portable/redirected environments (e.g. D:\claude-auth).
    $realLocalAppData = [System.Environment]::GetFolderPath('LocalApplicationData')
    $wtSettings = "$realLocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $wtSettings) {
        Write-Host "   Configuring Windows Terminal..." -ForegroundColor Gray
        try {
            $json = Get-Content $wtSettings -Raw | ConvertFrom-Json

            # ── xcad color scheme (black bg, navy/purple/magenta palette) ──
            # xcad: Campbell structure, all ANSI slots shifted to blues/purples
            $xcad = [PSCustomObject]@{
                name                = 'xcad'
                background          = '#0C0C0C'
                foreground          = '#CCCCCC'
                cursorColor         = '#C040E0'
                selectionBackground = '#3030A0'
                black               = '#0C0C0C'
                brightBlack         = '#767676'
                red                 = '#4040C0'
                brightRed           = '#6068E8'
                green               = '#0080A8'
                brightGreen         = '#00B8D4'
                yellow              = '#6050A8'
                brightYellow        = '#A890D8'
                blue                = '#0050D8'
                brightBlue          = '#4090FF'
                purple              = '#8020B0'
                brightPurple        = '#C040E0'
                cyan                = '#0090C8'
                brightCyan          = '#40C8F0'
                white               = '#CCCCCC'
                brightWhite         = '#F2F2F2'
            }
            $existingScheme = $json.schemes | Where-Object { $_.name -eq 'xcad' }
            if ($existingScheme) {
                # Update in place
                $json.schemes = @($json.schemes | Where-Object { $_.name -ne 'xcad' }) + $xcad
            } else {
                $json.schemes = @($json.schemes) + $xcad
            }

            # Set font + colorScheme in defaults (applies to all profiles)
            if (-not $json.profiles.defaults.font) {
                $json.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'font' -Value ([PSCustomObject]@{ face = 'CaskaydiaCove NF Mono'; size = 13 }) -Force
            } else {
                $json.profiles.defaults.font.face = 'CaskaydiaCove NF Mono'
            }
            if (-not $json.profiles.defaults.colorScheme) {
                $json.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'colorScheme' -Value 'xcad' -Force
            } else {
                $json.profiles.defaults.colorScheme = 'xcad'
            }

            # Switch default profile to PowerShell 7 if it's present and default is still PS5
            $ps7Guid = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'
            $ps5Guid = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
            $ps7Profile = $json.profiles.list | Where-Object { $_.guid -eq $ps7Guid }
            if ($ps7Profile -and $json.defaultProfile -eq $ps5Guid) {
                $json.defaultProfile = $ps7Guid
                Write-Ok "Default profile set to PowerShell 7"
            }

            $json | ConvertTo-Json -Depth 10 | Set-Content $wtSettings -Encoding UTF8
            Write-Ok "Windows Terminal: xcad scheme applied, font set to CaskaydiaCove NF Mono"
        } catch {
            Write-Warn "Could not update Windows Terminal settings: $_"
        }
    } else {
        Write-Warn "Windows Terminal settings not found — configure font and color scheme manually"
    }
} else {
    Write-Skip "Fonts"
}

# ── Oh My Posh ──
if (-not $SkipOhMyPosh) {
    Write-Step "Installing Oh My Posh"
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Invoke-Expression (Invoke-RestMethod 'https://ohmyposh.dev/install.ps1')
        Write-Ok "Oh My Posh installed"
    } else {
        Write-Ok "Oh My Posh already installed ($(oh-my-posh --version))"
    }
} else {
    Write-Skip "Oh My Posh"
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
if (-not $SkipFastfetch) {
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
} else {
    Write-Skip "Fastfetch config"
}

# ── Btop Config ──
if (-not $SkipBtop) {
    Write-Step "Installing btop config"
    $btopDir = "$env:APPDATA\btop"
    if (-not (Test-Path $btopDir)) { New-Item -ItemType Directory -Path $btopDir -Force | Out-Null }

    $btopSource = if ($scriptDir) { Join-Path $scriptDir "btop\btop.conf" } else { "" }
    if ($btopSource -and (Test-Path $btopSource)) {
        Copy-Item $btopSource "$btopDir\btop.conf" -Force
    } else {
        Invoke-WebRequest -Uri "$repoUrl/btop/btop.conf" -OutFile "$btopDir\btop.conf"
    }
    Write-Ok "Btop config installed to $btopDir\btop.conf"
} else {
    Write-Skip "Btop config"
}

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
if (-not $SkipDelta) {
    Write-Step "Configuring git to use delta"
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warn "git not found in PATH — skipping delta config. Re-run after git is installed."
    } elseif (Get-Command delta -ErrorAction SilentlyContinue) {
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
        Write-Skip "delta not found — install it first, then re-run without -SkipDelta"
    }
} else {
    Write-Skip "Git delta config"
}

# ── Summary ──
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  CaskaydiaCove Nerd Font Mono was installed automatically." -ForegroundColor Green
Write-Host "  Set it as your terminal font to enable prompt glyphs." -ForegroundColor Yellow
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
Write-Host "    y       - yazi file manager (cds on exit)" -ForegroundColor White
Write-Host "    fastfetch - system info on startup" -ForegroundColor White
Write-Host ""

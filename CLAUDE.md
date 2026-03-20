# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A PowerShell 7+ terminal enhancement suite. `install.ps1` is the single entry point that installs and configures a complete terminal setup: Oh My Posh prompt, PSReadLine predictions, fzf integration, modern CLI replacements, and a custom blue/purple theme.

## How It Works

`install.ps1` orchestrates everything in phases (each skippable via switch params):

1. **Scoop** (`-SkipScoop`) — Installs Scoop package manager, adds `extras`/`main` buckets, installs CLI tools
2. **Oh My Posh** (`-SkipOhMyPosh`) — Prompt engine
3. **PS Modules** (`-SkipModules`) — Terminal-Icons, PSFzf, PSCompletions
4. **Theme** (`-SkipTheme`) — Copies `custom-blue.omp.json` to `~\.poshthemes\`
5. **Fastfetch** (`-SkipFastfetch`) — Copies `fastfetch/config.jsonc` and `fastfetch/logo.txt` to `~\.config\fastfetch\`
6. **Profile** (`-SkipProfile`) — Backs up existing `$PROFILE`, copies `profile.ps1` into place
7. **Git delta** (`-SkipDelta`) — Configures git globally to use delta as pager

Each step is idempotent — checks for existing installs before acting.

## File Layout

| File | Purpose |
|------|---------|
| `install.ps1` | Main installer script (requires PowerShell 7+) |
| `profile.ps1` | PowerShell profile — aliases, keybindings, module imports |
| `custom-blue.omp.json` | Oh My Posh theme (blue/purple powerline, git status, exec time) |
| `.gitconfig-delta` | Reference git config for delta pager settings (not used by installer — for manual `[include]` use) |
| `fastfetch/config.jsonc` | Fastfetch system info display config |
| `fastfetch/logo.txt` | Custom ASCII logo for fastfetch |

## Running / Testing

```powershell
# Full install
./install.ps1

# Selective install (skip phases)
./install.ps1 -SkipScoop -SkipModules

# Remote one-liner install
irm https://raw.githubusercontent.com/h34tsink/pwsh-setup/main/install.ps1 | iex
```

No build step, no tests, no linting — this is a dotfiles/setup repo.

## Key Design Decisions

- **Dual sourcing**: Install script works both from a local clone (`$PSScriptRoot`) and via remote URL (`irm | iex`), falling back to GitHub raw URLs when `$PSScriptRoot` is empty
- **Tool binary map**: Scoop package names don't always match binary names (e.g., `ripgrep` installs as `rg`). The `$toolBinaryMap` hashtable in `install.ps1` handles this for idempotency checks.
- **Profile aliases shadow coreutils**: `cat` -> bat, `ls`/`ll`/`lt` -> eza, `find` -> fd, `lg` -> lazygit. All aliases are conditional on the tool being installed
- **PSFzf overrides Tab**: When PSFzf is loaded, Tab invokes `Invoke-FzfTabCompletion`; otherwise falls back to `MenuComplete`
- **Sensitive command filtering**: PSReadLine history handler filters lines containing password/secret/token/apikey/connectionstring
- **Nerd Font required**: The theme uses Nerd Font glyphs — won't render correctly without one (FiraCode or JetBrainsMono recommended)

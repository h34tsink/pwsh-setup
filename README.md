# pwsh-setup

A one-command PowerShell 7+ terminal enhancement suite. Installs and configures a modern terminal with Oh My Posh, predictive IntelliSense, fuzzy finding, and modern CLI tool replacements — all themed in blue/purple.

![Requires PowerShell 7+](https://img.shields.io/badge/PowerShell-7%2B-blue)

## Quick Install

**One-liner (recommended):**

```powershell
irm https://raw.githubusercontent.com/h34tsink/pwsh-setup/main/install.ps1 | iex
```

**Alternative using `iwr`:**

```powershell
& ([scriptblock]::Create((iwr https://raw.githubusercontent.com/h34tsink/pwsh-setup/main/install.ps1 -UseBasicParsing).Content))
```

**Clone and run:**

```powershell
git clone https://github.com/h34tsink/pwsh-setup.git
cd pwsh-setup
./install.ps1
```

### `irm` vs `iwr` — What's the Difference?

| | `irm` (`Invoke-RestMethod`) | `iwr` (`Invoke-WebRequest`) |
|---|---|---|
| **Returns** | Parsed content directly (text, JSON object, XML) | Full response object (headers, status code, content) |
| **Pipe to `iex`** | Works directly — returns the script as a string | Doesn't work — returns a response object, not a string. You need `.Content` first |
| **Use case** | Fetching content you want to use immediately | When you need response headers, status codes, or more control |

That's why `irm <url> | iex` just works, but with `iwr` you need to extract `.Content` before executing.

### What is `-UseBasicParsing` (`-useb`)?

In **Windows PowerShell 5.1**, `Invoke-WebRequest` uses Internet Explorer's DOM engine to parse HTML responses. The `-UseBasicParsing` (or `-useb`) flag skips IE parsing and returns raw content instead. Without it, `iwr` fails on machines where IE isn't configured (Server Core, etc.).

In **PowerShell 7+**, basic parsing is the default — `-useb` is accepted but does nothing. You only need it if your script might run on Windows PowerShell 5.1.

## What Gets Installed

### CLI Tools (via Scoop)

| Tool | Replaces | What it does |
|------|----------|-------------|
| [bat](https://github.com/sharkdp/bat) | `cat` | Syntax-highlighted file viewer |
| [eza](https://github.com/eza-community/eza) | `ls` | Modern `ls` with icons and git status |
| [fd](https://github.com/sharkdp/fd) | `find` | Fast, user-friendly file finder |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `grep` | Extremely fast text search |
| [fzf](https://github.com/junegunn/fzf) | — | Fuzzy finder for everything |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `cd` | Smart directory jumping (`z <partial>`) |
| [delta](https://github.com/dandavella/delta) | `diff` | Beautiful git diffs (side-by-side, syntax highlighting) |
| [lazygit](https://github.com/jesseduffield/lazygit) | — | Terminal UI for git |
| [btop](https://github.com/aristocratos/btop) | `top` | Resource monitor |
| [gsudo](https://github.com/gerardog/gsudo) | — | `sudo` for Windows |
| [gh](https://github.com/cli/cli) | — | GitHub CLI |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | — | System info on terminal startup |

### PowerShell Modules

- **[Terminal-Icons](https://github.com/devblackops/Terminal-Icons)** — File/folder icons in directory listings
- **[PSFzf](https://github.com/kelleyma49/PSFzf)** — fzf integration for tab completion and history search
- **[PSCompletions](https://github.com/abgox/PSCompletions)** — Tab completions for common CLI tools

### Prompt & Theme

- **[Oh My Posh](https://ohmyposh.dev/)** with a custom blue/purple powerline theme showing user, path, git status, execution time, and clock

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Ctrl+R` | Fuzzy history search (fzf) |
| `Ctrl+T` | Fuzzy file finder (fzf) |
| `Tab` | fzf tab completion (falls back to menu complete) |
| `Up/Down` | Search history matching current input |
| `Ctrl+Z` / `Ctrl+Y` | Undo / Redo |
| `Ctrl+W` | Delete word backward |
| `Alt+D` | Delete word forward |
| `Ctrl+D` | Delete character |
| `Ctrl+Left/Right` | Jump word backward/forward |

## Aliases

| Alias | Command | Notes |
|-------|---------|-------|
| `ls` | `eza --icons --group-directories-first` | |
| `ll` | `eza --icons --group-directories-first -la` | Long listing |
| `lt` | `eza --icons --group-directories-first --tree --level=2` | Tree view |
| `cat` | `bat` | Syntax highlighting |
| `find` | `fd` | |
| `lg` | `lazygit` | |
| `z <dir>` | `zoxide` | Smart cd — learns from usage |
| `sudo` | `gsudo` | Elevate commands |

## Skip Flags

Skip any section during install:

```powershell
./install.ps1 -SkipScoop        # Skip Scoop + all CLI tools
./install.ps1 -SkipOhMyPosh     # Skip Oh My Posh
./install.ps1 -SkipModules      # Skip PowerShell modules
./install.ps1 -SkipTheme        # Skip prompt theme
./install.ps1 -SkipFastfetch    # Skip fastfetch config
./install.ps1 -SkipProfile      # Skip profile installation
./install.ps1 -SkipDelta        # Skip git delta config

# Combine as needed
./install.ps1 -SkipScoop -SkipModules
```

## Prerequisites

- **PowerShell 7+** — [Install here](https://github.com/PowerShell/PowerShell/releases)
- **A Nerd Font** — Required for icons and prompt glyphs. Install from [nerdfonts.com](https://www.nerdfonts.com/font-downloads), then set it as your terminal font. Recommended: **FiraCode Nerd Font** or **JetBrainsMono Nerd Font**

## What the Installer Does

1. Installs [Scoop](https://scoop.sh/) package manager (if missing)
2. Adds `main` and `extras` Scoop buckets
3. Installs 12 CLI tools via Scoop
4. Installs Oh My Posh
5. Installs 3 PowerShell modules from PSGallery
6. Copies the custom Oh My Posh theme to `~\.poshthemes\`
7. Copies fastfetch config and logo to `~\.config\fastfetch\`
8. Backs up your existing `$PROFILE` and installs the new one
9. Configures git to use delta as the diff pager (side-by-side, Dracula theme)

Every step is idempotent — safe to run multiple times. Existing tools are detected and skipped.

## Uninstall

To revert, restore your backed-up profile:

```powershell
# Find backups
Get-ChildItem (Split-Path $PROFILE) -Filter "*.backup.*"

# Restore one
Copy-Item "$PROFILE.backup.20250320-141500" $PROFILE -Force
```

To remove Scoop tools: `scoop uninstall bat eza fd ripgrep delta btop gsudo lazygit fzf zoxide gh fastfetch`

To remove modules: `Uninstall-Module Terminal-Icons, PSFzf, PSCompletions`

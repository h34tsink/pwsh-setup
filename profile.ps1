# PowerShell Profile - Terminal Enhancement Suite
# Source: https://github.com/h34tsink/pwsh-setup

# --- Oh My Posh ---
oh-my-posh init pwsh --config "$HOME\.poshthemes\custom-blue.omp.json" | Invoke-Expression

# --- PSReadLine (Predictive IntelliSense) ---
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -MaximumHistoryCount 10000
Set-PSReadLineOption -HistoryNoDuplicates:$true
Set-PSReadLineOption -HistorySearchCursorMovesToEnd:$true
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -Colors @{
    Command            = '#87CEEB'
    Parameter          = '#98FB98'
    Operator           = '#FFB6C1'
    Variable           = '#DDA0DD'
    String             = '#FFDAB9'
    Number             = '#B0E0E6'
    Type               = '#F0E68C'
    Comment            = '#D3D3D3'
    Keyword            = '#b4befe'
    Error              = '#FF6347'
    InlinePrediction   = '#5a6a9f'
    ListPrediction     = '#c4a7fa'
    ListPredictionSelected = '#7b5cf5'
}

# Key bindings
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

# Don't save sensitive commands to history
Set-PSReadLineOption -AddToHistoryHandler {
    param($line)
    $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
    $hasSensitive = $sensitive | Where-Object { $line -match $_ }
    return ($null -eq $hasSensitive)
}

# --- Terminal-Icons ---
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# --- PSFzf (Fuzzy Finder) ---
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
}

# --- PSCompletions ---
if (Get-Module -ListAvailable -Name PSCompletions) {
    Import-Module PSCompletions
}

# --- gsudo Module ---
if (Test-Path "$HOME\scoop\modules\gsudoModule") {
    Import-Module gsudoModule
}

# --- Zoxide ---
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
}

# --- Delta (git pager) ---
if (Get-Command delta -ErrorAction SilentlyContinue) {
    $env:GIT_PAGER = 'delta'
}

# --- Aliases ---
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Set-Alias -Name cat -Value bat -Option AllScope
}
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls { eza --icons --group-directories-first @args }
    function ll { eza --icons --group-directories-first -la @args }
    function lt { eza --icons --group-directories-first --tree --level=2 @args }
}
if (Get-Command fd -ErrorAction SilentlyContinue) {
    Set-Alias -Name find -Value fd -Option AllScope
}
if (Get-Command lazygit -ErrorAction SilentlyContinue) {
    Set-Alias -Name lg -Value lazygit
}

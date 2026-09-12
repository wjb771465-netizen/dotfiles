# Windows PowerShell fragment: aliases, helper functions, PATH and prompt.
# Dot-sourced from the generated profile shim, see .config/powershell/profile.ps1.
# ASCII only: Windows PowerShell 5.1 parses BOM-less .ps1 files as ANSI.

# PowerShell maps curl/wget to Invoke-WebRequest. Drop them so the real
# curl.exe that ships with Windows stays reachable. No grep analogue exists.
Remove-Item Alias:curl, wget -ErrorAction SilentlyContinue

# Listing helpers (bash: ll='ls -alF', la='ls -A', l='ls -CF').
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }
function l  { Get-ChildItem @args }

# dotfiles management (bash alias `dotfiles` on macOS/Linux).
function dotfiles { git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" @args }

# Paths that live on main (macOS/Linux) but have no business in $HOME here. The
# windows branch tracks none of them; they only show up when a merge from main
# writes them back, which `dotfiles-sync` undoes.
$DotfilesUnixOnly = @(
    '.bashrc', '.bash_logout', '.bash_login', '.bash_aliases', '.inputrc',
    '.profile', '.zshrc', 'install.sh', '.agents', '.local',
    '.claude/hooks', '.cursor/mcp.json', '.config/bash', '.config/cursor', '.config/shell'
)

function Test-UnixOnly([string]$Rel) {
    foreach ($p in $DotfilesUnixOnly) {
        if ($Rel -eq $p -or $Rel.StartsWith("$p/")) { return $true }
    }
    return $false
}

# This branch's own updates.
function dotfiles-pull {
    dotfiles fetch origin
    dotfiles merge --ff-only origin/windows
    dotfiles status --short
}

# Bring main's changes in. Two things need undoing afterwards: paths this branch
# deleted but main kept editing come back as modify/delete conflicts, and paths
# main added since come back as plain additions. Both are dropped again, so the
# merge ends up with main's shared files and none of the unix-only ones.
function dotfiles-sync {
    dotfiles fetch origin
    dotfiles merge --no-edit origin/main
    $incoming = @(dotfiles diff --name-only --diff-filter=U) +
                @(dotfiles diff --cached --name-only --diff-filter=A)
    foreach ($rel in $incoming) {
        if (-not (Test-UnixOnly $rel)) { continue }
        $full = Join-Path $HOME ($rel -replace '/', '\')
        if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
        dotfiles rm -r -f --cached --quiet --ignore-unmatch -- $rel
        Write-Host "dotfiles-sync: dropped $rel (main-only)" -ForegroundColor DarkYellow
    }
    if (Test-Path -LiteralPath (Join-Path $HOME '.dotfiles\MERGE_HEAD')) {
        dotfiles commit --no-edit --quiet
    }
    dotfiles status --short
}

# $HOME\.local\bin on PATH (mirror of common.sh, guarded).
$dotfilesBin = Join-Path $HOME '.local\bin'
if ($env:PATH -notlike "*$dotfilesBin*") { $env:PATH = "$dotfilesBin;$env:PATH" }

# Prompt: green user, blue leaf dir, white git branch (ps1_short_dir_git.sh).
function prompt {
    $branch = ''
    $b = git rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $b) { $branch = " ($b)" }
    $leaf = Split-Path -Leaf (Get-Location)
    Write-Host ("{0}[01;32m{1}{0}[00m:{0}[01;34m{2}{0}[00m{0}[37m{3}{0}[00m$ " -f [char]27, $env:USERNAME, $leaf, $branch) -NoNewline
    return ' '
}

# Up/Down search history by prefix (bash: bind history-search-backward).
if (Get-Module PSReadLine) {
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# Not ported from common.sh: the conda/nvm lazy-load stubs (conda init owns
# conda here and there is no nvm on this box) and the Homebrew PATH block.

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

# Codex session shortcuts (mirror of common.sh's codex()): `codex -r` resumes,
# `codex -c` resumes the last session; everything else passes through.
function codex {
    $a = @($args)
    # npm also ships an extensionless shim; `&` can't run it, so prefer the .cmd.
    $exe = Get-Command codex -All -CommandType Application -ErrorAction Stop |
        Where-Object Extension | Select-Object -First 1
    if ($a.Count -gt 0 -and $a[0] -eq '-r') {
        & $exe resume @($a | Select-Object -Skip 1)
    } elseif ($a.Count -gt 0 -and $a[0] -eq '-c') {
        & $exe resume --last @($a | Select-Object -Skip 1)
    } else {
        & $exe @a
    }
}

# dotfiles management (bash alias `dotfiles` on macOS/Linux).
function dotfiles { git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" @args }

# Paths that live on main (macOS/Linux) but have no business in $HOME here. The
# windows branch tracks none of them; they only show up when a merge from main
# writes them back, which `dotfiles-sync` undoes. `.agents/skills` is absent on
# purpose: the skill bodies are tracked on both branches at the same paths.
$DotfilesUnixOnly = @(
    '.bashrc', '.bash_logout', '.bash_login', '.bash_aliases', '.inputrc',
    '.profile', '.zshrc', 'install.sh', '.local',
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

# Git for Windows can be installed "Git Bash only", which leaves git.exe off the
# machine PATH. The dotfiles helpers and the prompt below both shell out to git.
$gitBin = 'C:\Program Files\Git\cmd'
if ((Test-Path "$gitBin\git.exe") -and ($env:PATH -notlike "*$gitBin*")) {
    $env:PATH = "$gitBin;$env:PATH"
}

# Prompt: green user, blue leaf dir, white git branch (ps1_short_dir_git.sh).
function prompt {
    $branch = ''
    $b = git rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $b) { $branch = " ($b)" }
    $leaf = Split-Path -Leaf (Get-Location)
    # At a drive root (C:\) Split-Path -Leaf returns nothing; show the full path.
    if (-not $leaf) { $leaf = (Get-Location).Path }
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

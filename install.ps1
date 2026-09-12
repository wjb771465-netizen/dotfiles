# install.ps1 -- installs the `windows` branch of this dotfiles repo into $HOME.
#
# That branch carries exactly the files that belong in %USERPROFILE% on Windows,
# so this is a plain bare-repo checkout: no sparse patterns, no per-machine
# filters. macOS/Linux live on main; the two branches share history and are kept
# in step with `dotfiles-sync` (see .dotfiles/CLAUDE.md).
#
# Run:  powershell -NoProfile -ExecutionPolicy Bypass -File $HOME\install.ps1

$ErrorActionPreference = 'Stop'
# git prints paths as UTF-8; PowerShell would decode them with the OEM codepage.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Repo     = 'https://github.com/wjb771465-netizen/dotfiles.git'
$Branch   = 'windows'
$GitDir   = Join-Path $HOME '.dotfiles'
$WorkTree = $HOME

function DF {
    param([string[]]$Cmd)
    & git --git-dir=$GitDir --work-tree=$WorkTree @Cmd
}

Write-Host '==> Cloning the windows branch...'
if (Test-Path $GitDir) {
    Write-Host '    ~\.dotfiles already exists, skipping clone.'
} else {
    git clone --bare --single-branch --branch $Branch $Repo $GitDir
    if ($LASTEXITCODE -ne 0) { throw "clone failed ($LASTEXITCODE)" }
}
DF @('config', '--local', 'status.showUntrackedFiles', 'no')
# --single-branch leaves the clone without a refspec, and a bare clone keeps its
# branches local: without this, `dotfiles fetch` is a no-op and origin/main does
# not exist for dotfiles-sync.
DF @('config', '--local', 'remote.origin.fetch', '+refs/heads/*:refs/remotes/origin/*')

Write-Host '==> Backing up files that would block checkout...'
# git refuses to overwrite a work tree file that differs from the branch, so move
# those aside. The list comes from HEAD rather than from the index: right after a
# clone the index is still empty, and the work tree is all we can compare against.
$Backup = Join-Path $HOME '.dotfiles-backup'
foreach ($rel in (DF @('-c', 'core.quotePath=false', 'ls-tree', '-r', '--name-only', 'HEAD'))) {
    $full = Join-Path $WorkTree ($rel -replace '/', '\')
    if (-not (Test-Path -LiteralPath $full)) { continue }
    $local = git --git-dir=$GitDir hash-object --path=$rel $full
    $head  = DF @('rev-parse', "HEAD:$rel")
    if ($local -eq $head) { continue }
    $dest = Join-Path $Backup ($rel -replace '/', '\')
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Move-Item -LiteralPath $full -Destination $dest -Force
    Write-Host "    backed up: $rel"
}

Write-Host '==> Checking out...'
DF @('checkout')
# checkout reads a file missing from the work tree as a local deletion and leaves
# it that way, so force-materialise the index. This also puts back whatever the
# backup step moved away, and any file deleted by hand since the last install.
DF @('checkout-index', '-a', '-f')

Write-Host '==> Verifying...'
$dirty = DF @('status', '--short')
if ($dirty) { throw "work tree does not match HEAD:`n$dirty" }

Write-Host '==> Merging the profile shim...'
$template = Get-Content -LiteralPath (Join-Path $HOME '.config\powershell\profile.ps1') -Raw
$begin    = '# >>> dotfiles >>>'
$end      = '# <<< dotfiles <<<'
$marked   = [regex]::Match($template, '(?s)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end))
if (-not $marked.Success) { throw 'profile template is missing the dotfiles markers' }
$block = $marked.Value

foreach ($profile in @("$HOME\Documents\WindowsPowerShell\profile.ps1", "$HOME\Documents\PowerShell\profile.ps1")) {
    New-Item -ItemType Directory -Force -Path (Split-Path $profile) | Out-Null
    $current = if (Test-Path -LiteralPath $profile) { Get-Content -LiteralPath $profile -Raw } else { '' }
    if ($current -match [regex]::Escape($begin)) {
        $updated = [regex]::Replace($current, '(?s)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end), $block)
    } else {
        $updated = $current.TrimEnd() + "`r`n`r`n" + $block + "`r`n"
    }
    Set-Content -LiteralPath $profile -Value $updated -Encoding ASCII
    Write-Host "    $profile"
}

Write-Host ''
Write-Host 'Done. Remaining manual steps:'
Write-Host '  winget install Microsoft.PowerShell   # PowerShell 7 (optional)'
Write-Host '  conda init powershell                 # rewrites only its own region; re-run this script afterwards'
Write-Host ''
Write-Host 'Manage dotfiles with: dotfiles status / add / commit / push'
Write-Host 'Update this branch:   dotfiles-pull'
Write-Host 'Merge main into it:   dotfiles-sync'

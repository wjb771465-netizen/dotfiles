# dotfiles profile shim TEMPLATE.
# install.ps1 splices the marked block below into the real profiles and keeps
# everything else in them (in particular conda's own region):
#   %USERPROFILE%\Documents\WindowsPowerShell\profile.ps1   Windows PowerShell 5.1
#   %USERPROFILE%\Documents\PowerShell\profile.ps1          PowerShell 7
# Edit this template (or common.ps1 / proxy.ps1) and re-run install.ps1.
# ASCII only: Windows PowerShell 5.1 parses BOM-less .ps1 files as ANSI.
# >>> dotfiles >>>
$dotfilesCommon = Join-Path $HOME '.config\powershell\common.ps1'
if (Test-Path -LiteralPath $dotfilesCommon) { . $dotfilesCommon }
$dotfilesProxy = Join-Path $HOME '.config\powershell\proxy.ps1'
if (Test-Path -LiteralPath $dotfilesProxy) { . $dotfilesProxy }
# <<< dotfiles <<<

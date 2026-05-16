#!/usr/bin/env bash
set -euo pipefail

REPO="git@github.com:wjb771465-netizen/dotfiles.git"
PRIVATE_REPO="git@github.com:wjb771465-netizen/dotfiles-private.git"
DOT="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

# ─── Public dotfiles ───────────────────────────────────────────────────────────

echo "==> Cloning dotfiles..."
if [ ! -d "$HOME/.dotfiles" ]; then
  git clone --bare "$REPO" "$HOME/.dotfiles"
else
  echo "    ~/.dotfiles already exists, skipping clone."
fi

echo "==> Checking out..."
mkdir -p "$HOME/.dotfiles-backup"
conflicts=$($DOT checkout 2>&1 | awk '/^\t/{print $1}' || true)
if [ -n "$conflicts" ]; then
  echo "    Backing up conflicts to ~/.dotfiles-backup/"
  echo "$conflicts" | while IFS= read -r f; do
    mkdir -p "$HOME/.dotfiles-backup/$(dirname "$f")"
    mv "$HOME/$f" "$HOME/.dotfiles-backup/$f"
  done
  $DOT checkout
fi

$DOT config --local status.showUntrackedFiles no
echo "==> Public dotfiles ready."

# ─── Private config (optional) ─────────────────────────────────────────────────

echo ""
read -rp "Install private config (personal Claude skills, etc.)? [y/N] " yn
case "$yn" in
  [yY]*)
    echo "==> Setting up private config..."
    if [ ! -d "$HOME/.dotfiles-private" ]; then
      git clone --bare "$PRIVATE_REPO" "$HOME/.dotfiles-private"
    else
      echo "    ~/.dotfiles-private already exists, pulling latest..."
      git --git-dir="$HOME/.dotfiles-private" remote update
    fi
    PRIV="git --git-dir=$HOME/.dotfiles-private --work-tree=$HOME"
    $PRIV checkout 2>/dev/null || true
    $PRIV config --local status.showUntrackedFiles no
    echo "==> Private config ready."
    ;;
  *)
    echo "    Skipped. Run with: bash install.sh and choose y when prompted."
    ;;
esac

# ─── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "All done. Run 'source ~/.zshrc' (macOS) or 'source ~/.bashrc' (Linux)."
echo "Manage dotfiles with: dotfiles status / add / commit / push"

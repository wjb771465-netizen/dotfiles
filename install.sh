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

    # Adapt hardcoded /Users/wjb paths to actual $HOME
    if [ "$HOME" != "/Users/wjb" ]; then
      echo "    Adapting paths in Ruby prompts to $HOME..."
      find "$HOME/.claude/skills/Ruby/prompts" "$HOME/.claude/skills/Ruby/SKILL.md" \
        -type f -name "*.md" | xargs sed -i.bak "s|/Users/wjb|$HOME|g"
      find "$HOME/.claude/skills/Ruby" -name "*.bak" -delete
    fi

    echo "==> Private config ready."
    ;;
  *)
    echo "    Skipped. Run with: bash install.sh and choose y when prompted."
    ;;
esac

# ─── Claude Code plugins (idempotent) ─────────────────────────────────────────

PLUGINS=(
  "frontend-design@claude-plugins-official"
  "session-report@claude-plugins-official"
  "skill-creator@claude-plugins-official"
)
echo "==> Installing Claude Code plugins..."
for p in "${PLUGINS[@]}"; do
  claude plugin install "$p" >/dev/null 2>&1 \
    && echo "    installed: $p" \
    || echo "    skipped (already installed or claude unavailable): $p"
done

# ─── Cursor editor settings (draft → app path, one-way copy) ──────────────────
# 草稿 ~/.config/cursor/settings.json 是 source of truth；在 Cursor UI 里改完
# 设置后需手动回灌：cp "$HOME/Library/Application Support/Cursor/User/settings.json" ~/.config/cursor/settings.json

CURSOR_SETTINGS="$HOME/Library/Application Support/Cursor/User/settings.json"
if [ "$(uname)" = "Darwin" ] && [ -d "$(dirname "$CURSOR_SETTINGS")" ]; then
  echo "==> Deploying Cursor settings..."
  cp "$HOME/.config/cursor/settings.json" "$CURSOR_SETTINGS"
else
  echo "==> Skipping Cursor settings (Cursor app dir not found)."
fi

# ─── Optional: Cursor MCP servers (not installed by this script) ──────────────
#
# ~/.cursor/mcp.json 已包含 zotero / officecli 两个 MCP server 配置，但依赖以下
# 运行时组件，需要手动安装：
#
#   Zotero:   uv tool install zotero-mcp-server   # 提供 ~/.local/bin/zotero-mcp
#             + dotfiles-private 的 keys.sh (pass api/zotero)
#             + 本机 Zotero Desktop 需保持运行（ZOTERO_LOCAL=true）
#             启动脚本 ~/.local/bin/zotero-mcp-hybrid 已随本仓库同步
#
#   Office:   npm i -g @officecli/officecli       # 需要先装好 nvm/node
#
# 装好后重启 Cursor 或重新加载 MCP 即可生效。

# ─── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "All done. Run 'source ~/.zshrc' (macOS) or 'source ~/.bashrc' (Linux)."
echo "Manage dotfiles with: dotfiles status / add / commit / push"

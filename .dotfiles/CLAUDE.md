# dotfiles

## Background
个人开发环境配置，使用 bare git repo 方案管理（工作区为 `$HOME`，仓库存于 `~/.dotfiles`）。目标是将 shell、git、编辑器及 Claude Code 配置版本化，并支持跨设备一键安装。私有配置（Claude 技能等）通过独立的 `dotfiles-private` 可选安装。

## Key Paths
| 路径 | 用途 |
|------|------|
| `~/.dotfiles/` | bare git 仓库（非工作区） |
| `~/install.sh` | 一键安装脚本（含可选私有配置） |
| `~/.config/shell/common.sh` | bash/zsh 共享 alias 和 conda 激活 |
| `~/.bashrc` | bash 专用配置（Linux 服务器） |
| `~/.zshrc` | zsh 专用配置（macOS） |
| `~/.config/bash/ps1_short_dir_git.sh` | bash 自定义 PS1 prompt |
| `~/.profile` | login shell 基础配置 |
| `~/.gitconfig` | git 全局配置及别名（`br`/`co`/`lg`/`cmm` 等） |
| `~/.config/git/ignore` | 全局 gitignore |
| `~/.cursor/rules/coding-style.mdc` | Cursor 代码风格规则 |
| `~/.cursor/rules/agent-interaction.mdc` | Cursor AI 交互协议 |
| `~/.cursor/rules/git-commit.mdc` | Cursor git 提交工作流规则 |
| `~/.claude/settings.json` | Claude Code 通用配置 |

## Rules
- 日常管理用 `dotfiles` alias（= `git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME`）
- 私有配置（`~/.dotfiles-private/`）独立管理，不进入此 repo
- `git status` 默认隐藏未跟踪文件（`status.showUntrackedFiles no`）
- 私人技能存放在 `~/.claude/skills/`，由 `dotfiles-private` 管理

## Tech Stack
- Shell: bash（Linux）+ zsh（macOS）双栈
- 包管理: conda（miniconda3），默认激活 `jsbsim` 环境
- 编辑器: VS Code / Cursor（均配置为 git 默认编辑器）
- dotfiles 方案: bare git repo（`~/.dotfiles`），工作区为 `$HOME`

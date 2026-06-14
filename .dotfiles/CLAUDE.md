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
| `~/.claude/skills/context/` | context 技能（含 agent-layer 和 readme-layer prompts） |
| `~/.claude/skills/git-commit-push/` | git-commit-push 技能（conventional commit 生成 + 推送） |
| `~/.config/shell/keys.sh` | `key()` 函数，通过 pass 取 API key |
| `~/.password-store/` | GPG 加密的密钥仓库（pass，独立 git repo） |
| `~/.config/pass/` | GPG 密钥备份（dotfiles-private 跟踪） |
| `~/docs/pass-secrets-guide.md` | pass 密钥管理完整指南 |

## Rules
- 日常管理用 `dotfiles` alias（= `git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME`）
- 私有配置（`~/.dotfiles-private/`）独立管理，不进入此 repo
- `git status` 默认隐藏未跟踪文件（`status.showUntrackedFiles no`）
- 私人技能存放在 `~/.claude/skills/`，由 `dotfiles-private` 管理
- **API 密钥管理**：使用 `pass` + `$(key <name>)` 取值，禁止在配置文件或对话中写明文 key。三个仓库分工见 `pass-secrets-guide.md`

## Operational Constraints（bare repo 操作禁区）

以下操作在 `$HOME` 工作区下会引发严重性能问题或卡死，**必须避免**：

| 禁止操作 | 原因 | 替代方案 |
|----------|------|---------|
| `git stash --include-untracked` / `-u` | 会扫描整个 `$HOME` 下所有未跟踪文件，海量 pip/node 缓存导致卡死 | `git stash`（仅 tracked 文件），或直接 `git restore` 特定文件 |
| `git add -A` / `git add .` 不加路径限制 | 同上，会遍历整个家目录 | 明确指定文件路径：`git add .config/shell/common.sh` |
| `git clean -df` | 会递归删除 `$HOME` 下所有未跟踪文件，灾难性 | 永远不要执行 |

此外：
- `dotfiles` alias 在非交互式 shell（如 Claude Code 的 Bash 工具）中不可用——始终使用完整命令。**必须先 `cd $HOME`**，否则 `git add`/`restore`/`diff` 等涉及 pathspec 的操作会从当前目录解析相对路径而失败。完整公式：`cd $HOME && git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME <subcommand>`
- pull 前如有本地改动，优先 `git restore` 特定文件；但 bare repo 下 `restore` / `diff` / `ls-files` 可能因路径解析不一致而报不认识文件，此时 `git stash`（不带 `-u`）→ `pull` → `stash pop` 是可靠 fallback

## Tech Stack
- Shell: bash（Linux）+ zsh（macOS）双栈
- 包管理: conda（miniconda3），默认激活 `jsbsim` 环境
- 编辑器: VS Code / Cursor（均配置为 git 默认编辑器）
- dotfiles 方案: bare git repo（`~/.dotfiles`），工作区为 `$HOME`

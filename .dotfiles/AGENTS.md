# dotfiles

## Background
个人开发环境配置，使用 bare git repo 方案管理（工作区为 `$HOME`，仓库存于 `~/.dotfiles`）。目标是将 shell、git、编辑器及 agent 配置版本化，并支持跨设备一键安装。私有配置（个人技能等）通过独立的 `dotfiles-private` 可选安装。

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
| `~/.cursor/rules/workflow-prefs.mdc` | Cursor 工作流偏好（探索/Plan/完成标准；提交走 skill） |
| `~/.cursor/permissions.json` | Cursor Agent 终端/MCP 白名单与 Auto-review 倾向 |
| `~/.claude/settings.json` | Claude Code 通用配置 |
| `~/.agents/AGENTS.md` | Claude Code 与 Codex 共用的全局指令源文件 |
| `~/.claude/CLAUDE.md` | 指向 `~/.agents/AGENTS.md` 的相对软链 |
| `~/.codex/config.toml` | Codex 通用配置（本机文件，目前未纳入仓库） |
| `~/.codex/AGENTS.md` | 指向 `~/.agents/AGENTS.md` 的相对软链（Cursor 不自动加载；见 workflow-prefs） |
| `~/.agents/skills/` | 技能本体目录（cc-switch 统一存储） |
| `~/.claude/skills/` | Claude Code 技能软链，由 cc-switch 生成；Codex 直接读取 `~/.agents/skills/` |
| `~/.config/shell/keys.sh` | `key()` 函数，通过 pass 取 API key |
| `~/.password-store/` | GPG 加密的密钥仓库（pass，独立 git repo） |
| `~/.config/pass/` | GPG 密钥备份（dotfiles-private 跟踪） |
| `~/docs/pass-secrets-guide.md` | pass 密钥管理完整指南 |

## Rules
- 日常管理用 `dotfiles` alias（= `git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME`）
- 私有配置（`~/.dotfiles-private/`）独立管理，不进入此 repo
- 全局指令只编辑 `~/.agents/AGENTS.md`；Claude Code 和 Codex 的入口软链随本仓版本化
- `install.sh` 将 `status.showUntrackedFiles` 设为 `no`，避免日常状态检查扫描整个家目录
- 私人技能（Ruby、Xiya 等）由 `dotfiles-private` 管理，公开技能由本仓管理，分工见下方「Skills 与插件管理」
- Git 提交流程以 `git-commit-push` skill 为准，不要再维护平行的 Cursor git-commit rule
- **API 密钥管理**：使用 `pass` + `$(key <name>)` 取值，禁止在配置文件或对话中写明文 key。三个仓库分工见 `pass-secrets-guide.md`

## Skills 与插件管理

**技能（skills）**：
- 本体统一存放在 `~/.agents/skills/`，Codex 直接读取；cc-switch 向 Claude Code 等 agent 目录分发软链
- 编辑技能直接改 `~/.agents/skills/<name>/`，不要动其他 agent 目录下的软链
- **软链本身不进 git**（cc-switch 负责生成）；公开技能（无隐私内容）由本仓跟踪本体文件，私人技能由 `dotfiles-private` 跟踪
- 少数技能未被 cc-switch 收录时仍是对应 agent 技能目录中的实体文件，照常由对应仓跟踪

**插件（plugins）**：
- Claude Code 插件由 `install.sh` 的 `PLUGINS` 数组安装
- Codex 插件由应用管理，目前未写入 `install.sh`；安装状态不进 git

## Operational Constraints（bare repo 操作禁区）

以下操作在 `$HOME` 工作区下会引发严重性能问题或卡死，**必须避免**：

| 禁止操作 | 原因 | 替代方案 |
|----------|------|---------|
| `git stash --include-untracked` / `-u` | 会扫描整个 `$HOME` 下所有未跟踪文件，海量 pip/node 缓存导致卡死 | `git stash`（仅 tracked 文件），或直接 `git restore` 特定文件 |
| `git add -A` / `git add .` 不加路径限制 | 同上，会遍历整个家目录 | 明确指定文件路径：`git add .config/shell/common.sh` |
| `git clean -df` | 会递归删除 `$HOME` 下所有未跟踪文件，灾难性 | 永远不要执行 |

此外：
- `dotfiles` alias 在非交互式 shell（如 Codex 的 Bash 工具）中不可用——始终使用完整命令。**必须先 `cd $HOME`**，否则 `git add`/`restore`/`diff` 等涉及 pathspec 的操作会从当前目录解析相对路径而失败。完整公式：`cd $HOME && git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME <subcommand>`
- pull 前如有本地改动，优先 `git restore` 特定文件；但 bare repo 下 `restore` / `diff` / `ls-files` 可能因路径解析不一致而报不认识文件，此时 `git stash`（不带 `-u`）→ `pull` → `stash pop` 是可靠 fallback

## Tech Stack
- Shell: bash（Linux）+ zsh（macOS）双栈
- 包管理: conda（miniconda3），默认激活 `jsbsim` 环境
- 编辑器: VS Code / Cursor（均配置为 git 默认编辑器）
- dotfiles 方案: bare git repo（`~/.dotfiles`），工作区为 `$HOME`

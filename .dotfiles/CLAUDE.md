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
| `~/.cursor/rules/workflow-prefs.mdc` | Cursor 工作流偏好（探索/Plan/完成标准；提交走 skill） |
| `~/.cursor/permissions.json` | Cursor Agent 终端/MCP 白名单与 Auto-review 倾向 |
| `~/.claude/settings.json` | Claude Code 通用配置 |
| `~/.claude/CLAUDE.md` | Claude Code 用户级偏好（Cursor 不自动加载；见 workflow-prefs） |
| `~/.agents/skills/` | 技能本体目录（cc-switch 统一存储） |
| `~/.claude/skills/` | 技能软链，由 cc-switch 生成指向 `~/.agents/skills/` |
| `~/.config/shell/keys.sh` | `key()` 函数，通过 pass 取 API key |
| `~/.password-store/` | GPG 加密的密钥仓库（pass，独立 git repo） |
| `~/.config/pass/` | GPG 密钥备份（dotfiles-private 跟踪） |
| `~/docs/pass-secrets-guide.md` | pass 密钥管理完整指南 |
| `~/install.ps1` | Windows 安装脚本（bare repo + sparse 白名单 + profile 合并） |
| `~/.config/powershell/common.ps1` | PowerShell 别名/函数/PATH/prompt |
| `~/.config/powershell/proxy.ps1` | PowerShell 代理开关（探测 127.0.0.1:7892） |
| `~/.config/powershell/profile.ps1` | profile shim 模板（`# >>> dotfiles >>>` 标记块） |
| `~/Documents/WindowsPowerShell/profile.ps1` | PS 5.1 profile 入口（install.ps1 生成，不入 git） |
| `~/Documents/PowerShell/profile.ps1` | PowerShell 7 profile 入口（同上） |
| `~/.config/git/config.local` | 机器本地 git 覆盖项（untracked，由 `.gitconfig` 末尾 `[include]` 引入） |

## Rules
- 日常管理用 `dotfiles` alias（= `git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME`）
- 私有配置（`~/.dotfiles-private/`）独立管理，不进入此 repo
- `git status` 默认隐藏未跟踪文件（`status.showUntrackedFiles no`）
- 私人技能（Ruby、Xiya 等）由 `dotfiles-private` 管理，公开技能由本仓管理，分工见下方「Skills 与插件管理」
- Git 提交流程以 `git-commit-push` skill 为准，不要再维护平行的 Cursor git-commit rule
- **API 密钥管理**：使用 `pass` + `$(key <name>)` 取值，禁止在配置文件或对话中写明文 key。三个仓库分工见 `pass-secrets-guide.md`

## Skills 与插件管理

**技能（skills）**：
- 本体统一存放在 `~/.agents/skills/`，由 cc-switch 管理，软链分发到 `~/.claude/skills/` 等各 agent 目录
- 编辑技能直接改 `~/.agents/skills/<name>/`，不要动 `~/.claude/skills/` 下的软链
- **软链本身不进 git**（cc-switch 负责生成）；公开技能（无隐私内容）由本仓跟踪本体文件，私人技能由 `dotfiles-private` 跟踪
- 少数技能未被 cc-switch 收录时仍是 `~/.claude/skills/` 实体目录，照常由对应仓跟踪

**插件（plugins）**：
- Claude Code 插件由 `install.sh` 的 `PLUGINS` 数组统一安装，装新插件时同步加进去
- 插件安装状态由 Claude Code 自管（`claude plugin list`），不进 git

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

## Windows 侧（PowerShell，`windows` 分支）

Windows 用**独立分支** `windows`：它是 main 的子集 + Windows 专属文件，落地范围由分支的树本身决定，不用 sparse：

- **分支内容**：`windows` 从 main 分出，共享历史，多加一个「删掉 unix-only 文件」的提交（`.bashrc`/`.bash_logout`/`.bashrc` 系列/`.profile`/`.zshrc`/`install.sh`/`.agents/**`/`.local/**`/`.config/shell/**`/`.config/bash/**`/`.config/cursor/**`/`.claude/hooks/**`/`.cursor/mcp.json`）。不落地这些是硬要求：Git Bash 会读 `~/.bashrc`，且 MSYS 的 `/etc/profile.d/bash_profile.sh` 检测到它会自动生成 `~/.bash_profile` 并打 WARNING。
- **`windows` 上的文件**：`.config/powershell/{common,proxy,profile}.ps1`、`install.ps1`、`.gitattributes`，加上跨平台共用的 `.gitconfig`、`.config/git/ignore`、`.claude/CLAUDE.md`、`.cursor/{.gitignore,permissions.json,rules/**}`、`README.md`、`.dotfiles/CLAUDE.md`。Windows 侧要新增文件 → 加在这个分支上；要改跨平台文件 → 改哪个分支都行，但两边都改会在 `dotfiles-sync` 时冲突。
- **落地的机制**：`git clone --bare --single-branch --branch windows`（本地只有 `windows` 分支，避免误 checkout main 把 unix 文件泼进 `$HOME`）+ `install.ps1`。git 2.51 的 `clone --bare` 不写 `remote.origin.fetch`，install.ps1 会补上 `+refs/heads/*:refs/remotes/origin/*`，否则 `dotfiles fetch` 是空操作、`origin/main` 不存在。
- **install.ps1 的顺序**：`ls-tree HEAD` 预扫描（clone 后 index 还是空的，只有 HEAD 可查）→ 与 HEAD 不同的本地文件挪进 `~/.dotfiles-backup\`（比较用 `git hash-object --path=<rel>`，走 CRLF 归一化）→ `checkout` → **`checkout-index -a -f`**。最后这步不能省：`checkout` 把「worktree 里文件不存在」当成你自己的删除而跳过，被挪走的文件和手删的文件都靠它补回来。
- **更新**：`dotfiles-pull` = `fetch` + `merge --ff-only origin/windows`。**同步 main** 用 `dotfiles-sync`：`merge --no-edit origin/main` 会因 modify/delete 冲突停下（main 改过、本分支删过的文件会被写回 `$HOME`），脚本按 `diff --diff-filter=U`（冲突）和 `--cached --diff-filter=A`（main 新增）挑出 unix-only 路径，`rm -f` 掉再 `commit`。`-X ours` **不能**自动解决 modify/delete 冲突。
- profile 入口（`Documents\...\profile.ps1`）由 `install.ps1` 合并生成，保留 conda 的 `#region conda initialize` 块。改配置改 `~/.config/powershell/*.ps1`（或 `profile.ps1` 模板）后重跑 `install.ps1`，不要手改 Documents 下那两个文件。
- 新增 `.ps1` **必须纯 ASCII 注释/文本**：Windows PowerShell 5.1 对无 BOM 的 `.ps1` 按 ANSI(cp936) 解析，中文会乱码甚至吞掉换行导致语法错误。`.gitattributes` 把 `*.ps1` 钉成 LF。
- 机器本地差异（`safe.directory`、Windows 的 `core.autocrlf=true`）放 `~/.config/git/config.local`，不要写进 tracked 的 `.gitconfig`（那会让它在 `dotfiles status` 里长期 dirty）。
- 不在 Windows 上跑 `install.sh`（SSH remote + GNU `sed -i`）；`.claude/hooks/**` 刻意不带（guard 依赖 `python3`，本机是 Store stub，fail-closed 会让每次工具调用都弹权限）。
- provider 切换归 cc-switch（`~/.cc-switch`），**不要**在 Windows 上移植 `claude-providers.sh`；密钥链路（pass + `key()`）目前只在 macOS/Linux 侧，Windows 的 `.claude/settings.json` 里是明文 key（本地文件，gitignored）。

## Tech Stack
- Shell: bash（Linux）+ zsh（macOS）+ PowerShell（Windows 5.1 / 7，独立 `windows` 分支）三栈
- 包管理: conda（miniconda3），默认激活 `jsbsim` 环境
- 编辑器: VS Code / Cursor（均配置为 git 默认编辑器）
- dotfiles 方案: bare git repo（`~/.dotfiles`），工作区为 `$HOME`

# dotfiles

个人开发环境配置，使用 [bare git repo](https://www.atlassian.com/git/tutorials/dotfiles) 方案管理。

## 分支模型

- **`main`** — macOS（zsh）+ Linux（bash）。本 README 的 bash/zsh 两节属于它。
- **`windows`** — Windows（PowerShell 5.1 / 7），从 main 分出，两者共享历史。它**删掉了** unix-only 文件（`.bashrc`/`.zshrc`/`.profile`/`.local/**`/`install.sh`/`.config/shell/**` 等），所以 clone 下来落地到 `%USERPROFILE%` 的东西就是 Windows 该有的那些，不需要 sparse 之类的过滤。跨平台文件（`.gitconfig`、`.claude/CLAUDE.md`、`.cursor/rules/**`、`.agents/skills/**`）两个分支共用同一份 blob。
- main 的改动用 `dotfiles-sync` 并进来（见下）。

## 包含什么

### Shell（bash + zsh 双支持）

通用配置抽到 `.config/shell/common.sh`，bash 和 zsh 各自 source 它。

- **`.config/shell/common.sh`** — 共享配置（别名、彩色输出、dotfiles alias、conda 激活）
- **`.bashrc`** — bash 专用（Linux 服务器）
  - 自定义 PS1（通过 `ps1_short_dir_git.sh`）
  - bash 补全、history-search 按键绑定
  - conda `shell.bash` 初始化
- **`.zshrc`** — zsh 专用（macOS）
  - `vcs_info` 驱动的 prompt（绿色用户名 + 蓝色目录 + 白色 git 分支）
  - zsh 补全、history-search 按键绑定
  - conda `shell.zsh` 初始化
  - Homebrew PATH（`/opt/homebrew/bin`，macOS 专用）
  - 代理环境变量（HTTP/SOCKS5，本地端口 6004）
- **`.config/bash/ps1_short_dir_git.sh`** — bash 独立 prompt 脚本
- **`.profile`** — login shell 基础配置
- **`.bash_logout`** — shell 退出清屏

### PowerShell（Windows）

- **`.config/powershell/common.ps1`** — 别名/函数（`ll`/`la`/`l`、`dotfiles`/`dotfiles-pull`）、`$HOME\.local\bin` PATH、绿用户名+蓝目录+白 git 分支的 prompt、PSReadLine 上下键前缀搜历史
- **`.config/powershell/proxy.ps1`** — `proxy {on|off|status|auto}`，TCP 探测 127.0.0.1:7892（Clash），起 shell 时执行 `proxy auto`
- **`.config/powershell/profile.ps1`** — profile shim 模板（`# >>> dotfiles >>>` 标记块，由 install.ps1 合并进真实 profile）
- **`install.ps1`** — Windows 安装脚本（bare repo + 冲突备份 + checkout + profile 合并）

### Git

- **`.gitconfig`** — Git 配置
  - 丰富的别名：`br`/`co`/`df`/`st`/`lg`/`cmm`/`rbi` 等
  - `lg` 系列格式化日志（彩色、图形、缩写哈希）
  - `pull.rebase = true`
  - VS Code / Cursor 作为默认编辑器
- **`.config/git/ignore`** — 全局 gitignore（OS 垃圾文件、Python/C++ 产物、编辑器临时文件、Jupyter checkpoints）

### Cursor IDE

- **`.cursor/rules/coding-style.mdc`** — 代码风格：禁止冗余防御代码、空 except、过多中间变量
- **`.cursor/rules/agent-interaction.mdc`** — AI 交互协议：遇矛盾时停止报告
- **`.cursor/rules/workflow-prefs.mdc`** — 探索问答、Plan、改动范围、完成标准；提交走 git-commit-push skill
- **`.cursor/permissions.json`** — Agent 终端/MCP 白名单 + Auto-review 倾向（Settings → Agents → Approvals & Execution 需开启 Run Mode）

Cursor 也会从 `~/.claude/skills/` 加载 Skills（与 Claude Code 共用，无需复制到 `~/.cursor/skills/`）。

### Claude Code

- **`.claude/settings.json`** — CC 通用配置（theme、hooks 等）
- **`.claude/CLAUDE.md`** — CC 用户级偏好（Cursor 不自动加载此文件；对应内容在 `workflow-prefs.mdc`）
- **`.claude/skills/context/`** — `/context` 技能：自动生成/更新 CLAUDE.md 和 README.md
- **`.claude/skills/git-commit-push/`** — 提交/推送技能（Cursor 与 CC 共用）

私人技能（如 `~/.claude/skills/Ruby/`）存放在独立的私有 repo `dotfiles-private`，通过 `install.sh` 可选安装，不进入此 repo。

## 新设备安装

### 快速安装（推荐）

```bash
git clone --bare git@github.com:wjb771465-netizen/dotfiles.git $HOME/.dotfiles
bash $HOME/.dotfiles/install.sh   # 会询问是否安装私人配置
```

> `install.sh` 自动处理冲突备份、alias 设置、隐藏未跟踪文件，末尾可选安装私人配置（Ruby 等）。

### 手动安装

<details>
<summary>展开手动步骤</summary>

```bash
# 1. 克隆
git clone --bare git@github.com:wjb771465-netizen/dotfiles.git $HOME/.dotfiles

# 2. 临时 alias
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# 3. 备份冲突文件后 checkout
mkdir -p $HOME/.dotfiles-backup
dotfiles checkout 2>&1 | awk '/^\t/{print $1}' | while IFS= read -r f; do
  mkdir -p "$HOME/.dotfiles-backup/$(dirname "$f")" && mv "$HOME/$f" "$HOME/.dotfiles-backup/$f"
done
dotfiles checkout

# 4. 隐藏未跟踪文件
dotfiles config --local status.showUntrackedFiles no

# 5. 生效
source ~/.zshrc   # macOS
# source ~/.bashrc  # Linux
```

</details>

### Windows（PowerShell）

```powershell
git clone --bare --single-branch --branch windows https://github.com/wjb771465-netizen/dotfiles.git $HOME\.dotfiles
powershell -NoProfile -ExecutionPolicy Bypass -File $HOME\install.ps1
```

Windows 用 `windows` 分支，同样是 bare repo + work-tree=`$HOME`（remote 走 HTTPS + Git Credential Manager）：

- **落地范围由分支本身决定**：clone 的是 `windows` 分支，它的树里只有该出现在 `%USERPROFILE%` 的文件（`.config/powershell/**`、`install.ps1`、`.gitattributes`、`.agents/skills/**`，加上跨平台的 `.gitconfig`/`.config/git/ignore`/`.claude/CLAUDE.md`/`.cursor/**`/`README.md`/`.dotfiles/CLAUDE.md`），所以没有 sparse 过滤，也不需要 `--single-branch` 之外的裁剪。unix-only 文件在分支的删除提交里，永远不会被 checkout 出来。
- **profile 入口由 install.ps1 合并生成**（保留 conda 的 `#region conda initialize`）：`Documents\WindowsPowerShell\profile.ps1`（PS 5.1）与 `Documents\PowerShell\profile.ps1`（PS7）。这两个文件不在 git 里，**改配置请改 `~/.config/powershell/*.ps1` 后重跑 install.ps1**。
- install.ps1 会先把与分支内容不同、会挡住 checkout 的本地文件挪进 `~/.dotfiles-backup\`，再 checkout，然后用 `checkout-index -a -f` 补齐（`checkout` 会把"文件不存在"当成你自己的删除而跳过）。
- **技能（skills）**：`.agents/skills/**` 与 main 同路径落地（共用 blob，main 上改技能会随 `dotfiles-sync` 过来）；`~/.claude/skills/<name>` 那层链接由 cc-switch 生成，不进 git。`.gitattributes` 把 `*.sh` 钉成 LF —— 本机的 `core.autocrlf=true` 否则会把 skill 里的 `scripts/*.sh` 检出成 CRLF，Git Bash 跑不了。
- 机器本地 git 覆盖项放 `~/.config/git/config.local`（untracked，由 `.gitconfig` 末尾的 `[include]` 引入）。
- **不要在 Windows 上 `dotfiles checkout main`**：main 的树里有 unix 文件，checkout 会把它们写进 `%USERPROFILE%`。clone 用了 `--single-branch`，本地没有 main 分支。
- 不要在 Windows 上跑 `install.sh`（SSH remote + GNU sed）。
- Windows 的 provider 切换归 cc-switch，`claude-providers.sh` 不移植；密钥链路（pass + `key()`）仍只在 macOS/Linux 侧。

### 日常管理

```bash
dotfiles status
dotfiles add ~/.claude/settings.json
dotfiles commit -m "update cc settings"
dotfiles push
dotfiles-pull   # 拉本分支（windows）的更新
dotfiles-sync   # Windows：把 main 的改动并进来，并删掉随之带出的 unix-only 文件
```

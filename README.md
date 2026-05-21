# dotfiles

个人开发环境配置，使用 [bare git repo](https://www.atlassian.com/git/tutorials/dotfiles) 方案管理。

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
- **`.cursor/rules/git-commit.mdc`** — Git 提交工作流：Conventional Commits、分支保护

### Claude Code

- **`.claude/settings.json`** — CC 通用配置（theme 等）
- **`.claude/skills/context/`** — `/context` 技能：自动生成/更新 CLAUDE.md 和 README.md
- **`.claude/skills/git-commit-push/`** — `/git-commit-push` 技能：conventional commit 生成 + 推送

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

### 日常管理

```bash
dotfiles status
dotfiles add ~/.claude/settings.json
dotfiles commit -m "update cc settings"
dotfiles push
```

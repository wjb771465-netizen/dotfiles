# dotfiles

个人开发环境配置，使用 [bare git repo](https://www.atlassian.com/git/tutorials/dotfiles) 方案管理。

## 包含什么

### Shell (`bash`)

- **`.bashrc`** — 主 shell 配置
  - 自定义 PS1 prompt（绿色用户名 + 蓝色目录 + 白色 git 分支）
  - 上下箭头按前缀搜索历史（`history-search-backward/forward`）
  - ls/grep 彩色输出、常用别名（`ll`、`la`、`l`）
  - conda (miniconda3) 初始化
  - `dotfiles` alias 用于管理本仓库
- **`.config/bash/ps1_short_dir_git.sh`** — 独立可移植的 prompt 脚本
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

## 新设备安装

### 1. 克隆

```bash
git clone --bare git@github.com:wjb771465-netizen/dotfiles.git $HOME/.dotfiles
```

### 2. 定义 alias

```bash
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

### 3. Checkout

```bash
dotfiles checkout
```

如果新机器上已有默认配置文件（`.bashrc` 等）导致冲突，先备份再重试：

```bash
mkdir -p $HOME/.dotfiles-backup
dotfiles checkout 2>&1 | grep -oP '(?<=\t).*' | xargs -I{} sh -c 'mkdir -p "$HOME/.dotfiles-backup/$(dirname "{}")" && mv "$HOME/{}" "$HOME/.dotfiles-backup/{}"'
dotfiles checkout
```

### 4. 隐藏未跟踪文件

```bash
dotfiles config --local status.showUntrackedFiles no
```

### 5. 完成

`source ~/.bashrc`，所有配置即刻生效。之后用 `dotfiles` 命令管理：

```bash
dotfiles status
dotfiles add ~/.bashrc
dotfiles commit -m "update bashrc"
dotfiles push
```

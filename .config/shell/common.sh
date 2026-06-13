# ~/.config/shell/common.sh — bash/zsh 共享配置
# 由 .bashrc 和 .zshrc 分别 source

# ─── Aliases ───

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias dotfiles-private='git --git-dir=$HOME/.dotfiles-private/ --work-tree=$HOME'

# ls/grep 彩色输出（跨平台）
if command -v dircolors &>/dev/null; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
elif [[ "$OSTYPE" == darwin* ]]; then
    export CLICOLOR=1
fi
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ─── PATH ───
case ":$PATH:" in
  *:"$HOME/.local/bin":*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# ─── API Keys (via pass) ───
source ~/.config/shell/keys.sh
export SILICONFLOW_API_KEY=$(key siliconflow)
export OPENAI_API_KEY=$SILICONFLOW_API_KEY
export ANTHROPIC_AUTH_TOKEN=$(key deepseek)

# ─── DeepSeek (via Anthropic compat) ───
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export ANTHROPIC_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_MODEL=deepseek-v4-flash
export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
export CLAUDE_CODE_EFFORT_LEVEL=max

# ─── NVM ───
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ─── macOS ───
export BASH_SILENCE_DEPRECATION_WARNING=1

# ─── Homebrew ───
# export PATH="/opt/homebrew/bin:$PATH"
# export HOMEBREW_RUBY_PATH=/usr/bin/ruby
# export HOMEBREW_NO_AUTO_UPDATE=1

# ─── Claude Code login mode ───
# 默认走 Claude Code 官方 OAuth；注释掉本段 unset 可切回上面的 Anthropic 兼容 API 配置。
unset ANTHROPIC_AUTH_TOKEN
unset ANTHROPIC_BASE_URL
unset ANTHROPIC_MODEL
unset ANTHROPIC_DEFAULT_MODEL
unset ANTHROPIC_DEFAULT_HAIKU_MODEL
unset CLAUDE_CODE_SUBAGENT_MODEL

# ─── Proxy ───
# 代理工具（梯子）本地监听端口；HTTP/HTTPS 走 7892（小鸡快跑），SOCKS5 同端口
export HTTP_PROXY=http://127.0.0.1:7892
export HTTPS_PROXY=http://127.0.0.1:7892
export ALL_PROXY=socks5://127.0.0.1:7892
export NO_PROXY=localhost,127.0.0.1,*.local

# ─── Conda ───
# 各 shell 的 conda init 块不同（bash vs zsh），留在各自 rc 文件中。
# 这里只做通用的环境激活。
if command -v conda &>/dev/null; then
    conda activate jsbsim 2>/dev/null
fi

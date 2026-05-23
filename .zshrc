# ~/.zshrc — zsh interactive shell config (macOS 默认 shell)

# ─── History ───
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt APPEND_HISTORY
setopt SHARE_HISTORY

# ─── Prompt ───
# 绿色用户名:蓝色末级目录 (白色 git 分支)$
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{green}%n%f:%F{blue}%1~%f%F{white}${vcs_info_msg_0_}%f$ '

# ─── Shared config (aliases, etc.) ───
[ -f "$HOME/.config/shell/common.sh" ] && . "$HOME/.config/shell/common.sh"

# ─── Key bindings (zsh-specific) ───
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ─── Completion ───
autoload -Uz compinit && compinit

# ─── Conda (zsh) ───
__conda_setup="$("$HOME/miniconda3/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/miniconda3/etc/profile.d/conda.sh"
    fi
fi
unset __conda_setup

# macOS bash deprecation warning 静默（如果从 bash profile 转过来）
export BASH_SILENCE_DEPRECATION_WARNING=1
export PATH="$HOME/.local/bin:$PATH"

# ─── Homebrew ───
# export PATH="/opt/homebrew/bin:$PATH"
# export HOMEBREW_RUBY_PATH=/usr/bin/ruby
# export HOMEBREW_NO_AUTO_UPDATE=1

# ─── API Keys (via pass) ───
export SILICONFLOW_API_KEY=$(key siliconflow)
export OPENAI_API_KEY=$SILICONFLOW_API_KEY
export ANTHROPIC_AUTH_TOKEN=$(key deepseek)

# ─── Proxy ───
# 代理工具（梯子）本地监听端口；HTTP/HTTPS 走 6004，SOCKS5 同端口
# export HTTP_PROXY=http://127.0.0.1:6004
# export HTTPS_PROXY=http://127.0.0.1:6004
# export ALL_PROXY=socks5://127.0.0.1:6004
# export NO_PROXY=localhost,127.0.0.1,*.

# ─── DeepSeek (via Anthropic compat) ───
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export ANTHROPIC_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_MODEL=deepseek-v4-flash
export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
export CLAUDE_CODE_EFFORT_LEVEL=max

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

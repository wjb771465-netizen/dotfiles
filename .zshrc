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

# ─── Shared config (aliases, PATH, keys, DeepSeek, NVM, etc.) ───
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

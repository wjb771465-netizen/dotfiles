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

# ─── API Keys (via pass; optional — keys.sh lives in dotfiles-private) ───
[[ -f ~/.config/shell/keys.sh ]] && source ~/.config/shell/keys.sh

# ─── Claude Code provider switcher ───
[[ -f ~/.config/shell/claude-providers.sh ]] && source ~/.config/shell/claude-providers.sh

# ─── NVM (lazy) ───
# 第一次调用 nvm/node/npm/npx 时再 source nvm.sh
export NVM_DIR="$HOME/.nvm"
_load_nvm() {
    unset -f nvm node npm npx _load_nvm
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
}
nvm()  { _load_nvm; nvm "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm "$@"; }
npx()  { _load_nvm; npx "$@"; }

# ─── macOS ───
export BASH_SILENCE_DEPRECATION_WARNING=1

# ─── Homebrew ───
export PATH="/opt/homebrew/bin:$PATH"
export HOMEBREW_RUBY_PATH=/usr/bin/ruby
export HOMEBREW_NO_AUTO_UPDATE=1

# ─── Proxy ───
[[ -f ~/.config/shell/proxy.sh ]] && source ~/.config/shell/proxy.sh

# ─── Conda (lazy) ───
# 第一次调用 conda 时再注入 shell hook（bash/zsh 各自不同）
conda() {
    unset -f conda
    local __conda_setup __shell
    if [ -n "${ZSH_VERSION:-}" ]; then
        __shell=zsh
    else
        __shell=bash
    fi
    __conda_setup="$("$HOME/miniconda3/bin/conda" "shell.$__shell" "hook" 2>/dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/miniconda3/bin:$PATH"
    fi
    conda "$@"
}

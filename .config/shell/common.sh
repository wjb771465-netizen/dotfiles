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

# ─── Conda ───
# 各 shell 的 conda init 块不同（bash vs zsh），留在各自 rc 文件中。
# 这里只做通用的环境激活。
if command -v conda &>/dev/null; then
    conda activate jsbsim 2>/dev/null
fi

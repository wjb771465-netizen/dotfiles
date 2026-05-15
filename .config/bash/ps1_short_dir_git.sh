# bash PS1：用户名:仅最后一级目录(\W)；非 Git 仓库不显示；Git 分支在路径后、白色括号内。
#
# === 复用到其他环境 ===
# 1) 复制本文件到目标机同路径，或放到任意目录并改下方 source 路径。
# 2) 在 ~/.bashrc 里须先保留（或等价实现）对 color_prompt 的检测，典型为：
#    case "$TERM" in xterm-color|*-256color) color_prompt=yes;; esac
#    以及可选的 force_color_prompt / tput 检测块。
# 3) 在上述检测之后、任意默认 PS1 覆盖之前，追加一行：
#    [ -f "$HOME/.config/bash/ps1_short_dir_git.sh" ] && . "$HOME/.config/bash/ps1_short_dir_git.sh"
#
# === 给 AI 的一行说明（提示词）===
# 「bash 交互提示符：绿用户名，冒号，蓝底路径只显示最后一级(\W)，若在 git 仓库则在后面加白色括号和当前分支名；xterm 标题同步为 user: 末级目录 (分支)。」
#

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}'"\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\033[37m\]\$(b=\$(git rev-parse --abbrev-ref HEAD 2>/dev/null); [ -n \"\$b\" ] && echo \" (\$b)\")\[\033[00m\]\\\$ "
else
    PS1='${debian_chroot:+($debian_chroot)}'"\u:\W\$(b=\$(git rev-parse --abbrev-ref HEAD 2>/dev/null); [ -n \"\$b\" ] && echo \" (\$b)\")\\\$ "
fi

unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u: \W\$(b=\$(git rev-parse --abbrev-ref HEAD 2>/dev/null); [ -n \"\$b\" ] && echo \" (\$b)\")\a\]$PS1"
    ;;
*)
    ;;
esac

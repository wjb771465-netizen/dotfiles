# ~/.config/shell/keys.sh — API key helper via pass
# 用法: $(key <name>)，key 明文仅存在于该命令进程中，用完即消失

key() {
  case "$1" in
    openai)       pass show api/openai ;;
    github)       pass show api/github ;;
    anthropic)    pass show api/anthropic ;;
    deepseek)     pass show api/deepseek ;;
    siliconflow)  pass show api/siliconflow ;;
    kimi)         pass show api/kimi ;;
    *) echo "unknown key: $1" >&2; return 1 ;;
  esac
}

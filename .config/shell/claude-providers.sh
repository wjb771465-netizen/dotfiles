# ~/.config/shell/claude-providers.sh — Claude Code provider 切换
# 默认仍走官方 Claude；以下函数用于临时切换到其他 provider，
# 环境变量只影响本次 claude 启动，不污染当前 shell。

claude-official() {
    env -u ANTHROPIC_API_KEY \
        -u ANTHROPIC_BASE_URL \
        -u ANTHROPIC_MODEL \
        -u ANTHROPIC_DEFAULT_MODEL \
        -u ANTHROPIC_DEFAULT_HAIKU_MODEL \
        -u CLAUDE_CODE_SUBAGENT_MODEL \
        claude "$@"
}

claude-kimi() {
    ANTHROPIC_AUTH_TOKEN="$(key kimi)" \
    ANTHROPIC_BASE_URL=https://api.kimi.com/coding/ \
    CLAUDE_CODE_AUTO_COMPACT_WINDOW=262144 \
    CLAUDE_CODE_EFFORT_LEVEL=max \
    env -u ANTHROPIC_MODEL \
        -u ANTHROPIC_DEFAULT_MODEL \
        -u ANTHROPIC_DEFAULT_HAIKU_MODEL \
        -u CLAUDE_CODE_SUBAGENT_MODEL \
        claude "$@"
}

claude-deepseek() {
    ANTHROPIC_AUTH_TOKEN="$(key deepseek)" \
    ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic \
    ANTHROPIC_MODEL=deepseek-v4-pro[1m] \
    ANTHROPIC_DEFAULT_MODEL=deepseek-v4-flash \
    ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash \
    CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash \
    env claude "$@"
}

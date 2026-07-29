# ~/.config/shell/proxy.sh — 本地代理开关
# 代理工具（梯子）本地监听端口。proxy() 一个命令同时切换 shell 环境变量和
# Cursor IDE 的 http.proxy 设置；proxy auto 按端口是否在监听自动决定当前 shell。

PROXY_PORT="${PROXY_PORT:-7892}"
_PROXY_CURSOR_SETTINGS="$HOME/Library/Application Support/Cursor/User/settings.json"

_proxy_probe() {
    nc -z -w1 127.0.0.1 "$1" 2>/dev/null
}

_proxy_shell_on() {
    export HTTP_PROXY="http://127.0.0.1:$1"
    export HTTPS_PROXY="http://127.0.0.1:$1"
    export ALL_PROXY="socks5://127.0.0.1:$1"
    export NO_PROXY="localhost,127.0.0.1,*.local"
}

_proxy_shell_off() {
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
}

# 改写 Cursor settings.json 的 http.proxy*；文件不存在（如 Linux 服务器）时静默跳过。
_proxy_cursor_set() {
    [[ -f "$_PROXY_CURSOR_SETTINGS" ]] || return 0
    if _PROXY_JSON_PORT="$1" _PROXY_JSON_SUPPORT="$2" python3 - "$_PROXY_CURSOR_SETTINGS" <<'PYEOF'
import json, os, sys

path = sys.argv[1]
port = os.environ["_PROXY_JSON_PORT"]
support = os.environ["_PROXY_JSON_SUPPORT"]

with open(path) as f:
    data = json.load(f)

if support == "off":
    data["http.proxySupport"] = "off"
    data.pop("http.proxy", None)
    data.pop("http.proxyStrictSSL", None)
else:
    data["http.proxy"] = f"http://127.0.0.1:{port}"
    data["http.proxySupport"] = "override"
    data["http.proxyStrictSSL"] = False

with open(path, "w") as f:
    json.dump(data, f, indent=4)
    f.write("\n")
PYEOF
    then
        echo "    (Cursor settings.json updated — reload window to apply)"
    else
        echo "    (failed to update Cursor settings.json)" >&2
        return 1
    fi
}

proxy() {
    local action="${1:-status}" port="${2:-$PROXY_PORT}"
    case "$action" in
        on)
            _proxy_shell_on "$port"
            _proxy_cursor_set "$port" override
            echo "proxy on (port $port)"
            ;;
        off)
            _proxy_shell_off
            _proxy_cursor_set "" off
            echo "proxy off"
            ;;
        auto)
            if _proxy_probe "$port"; then _proxy_shell_on "$port"; else _proxy_shell_off; fi
            ;;
        status)
            if _proxy_probe "$port"; then echo "port $port: listening"; else echo "port $port: not listening"; fi
            echo "shell HTTP_PROXY: ${HTTP_PROXY:-<unset>}"
            if [[ -f "$_PROXY_CURSOR_SETTINGS" ]]; then
                python3 -c "
import json
d = json.load(open('$_PROXY_CURSOR_SETTINGS'))
print('cursor http.proxy:', d.get('http.proxy', '<unset>'))
print('cursor http.proxySupport:', d.get('http.proxySupport', '<unset>'))
"
            else
                echo "cursor settings.json: not found"
            fi
            ;;
        *)
            echo "usage: proxy {on|off|status|auto} [port]" >&2
            return 1
            ;;
    esac
}

proxy auto

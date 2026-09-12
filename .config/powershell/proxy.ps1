# Proxy helpers: port of .config/shell/proxy.sh for Windows.
# Clash listens on 127.0.0.1:7892; `proxy auto` runs when the profile loads.
# ASCII only: Windows PowerShell 5.1 parses BOM-less .ps1 files as ANSI.
# The latency measurement of `proxy status` (curl + google/huawei fallback) is
# not ported; a TCP probe is enough to answer "is Clash up".

$env:PROXY_PORT = if ($env:PROXY_PORT) { $env:PROXY_PORT } else { '7892' }

function _proxy_probe([int]$Port = $env:PROXY_PORT) {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $client.ConnectAsync('127.0.0.1', $Port).Wait(300) | Out-Null
        return $client.Connected
    } catch { return $false }
    finally { $client.Close() }
}

function _proxy_shell_on([int]$Port = $env:PROXY_PORT) {
    $env:HTTP_PROXY  = "http://127.0.0.1:$Port"
    $env:HTTPS_PROXY = "http://127.0.0.1:$Port"
    $env:ALL_PROXY   = "socks5://127.0.0.1:$Port"
    $env:NO_PROXY    = 'localhost,127.0.0.1,*.local'
}

function _proxy_shell_off {
    foreach ($v in 'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'NO_PROXY') {
        Remove-Item "env:$v" -ErrorAction SilentlyContinue
    }
}

function proxy {
    param([string]$Action = 'status', [int]$Port = $env:PROXY_PORT)
    switch ($Action) {
        'on'   { _proxy_shell_on $Port; "proxy on (port $Port)" }
        'off'  { _proxy_shell_off; "proxy off" }
        'auto' { if (_proxy_probe $Port) { _proxy_shell_on $Port } else { _proxy_shell_off } }
        'status' {
            if (_proxy_probe $Port) { "port $Port : up" } else { "port $Port : down" }
            foreach ($v in 'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'NO_PROXY') {
                "{0,-11} {1}" -f $v, (Get-Item "env:$v" -ErrorAction SilentlyContinue).Value
            }
        }
        default { "usage: proxy {on|off|status|auto} [port]"; return 1 }
    }
}

proxy auto

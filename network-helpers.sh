# network-helpers.sh -- source me, don't execute me.
# Networking conveniences. No `set -e` here; this file gets sourced.

# shellcheck shell=bash

# wait_for_port <host> <port> [timeout_seconds] -- block until the port accepts
# a TCP connection, or time out. Returns 0 on success, 1 on timeout.
#
# Uses `nc` if available, else bash's /dev/tcp (bash-only). Prints dots so you
# can see it's alive. Usage: wait_for_port localhost 5432 30
wait_for_port() {
    local host="${1:-localhost}"
    local port="${2:-}"
    local timeout="${3:-30}"
    [[ -z "$port" ]] && { echo "usage: wait_for_port <host> <port> [timeout=30]" >&2; return 2; }

    local start now elapsed
    start="$(date +%s)"
    printf 'waiting for %s:%s ' "$host" "$port"

    while :; do
        if command -v nc >/dev/null 2>&1; then
            nc -z "$host" "$port" >/dev/null 2>&1 && { printf ' ok\n'; return 0; }
        else
            # bash built-in TCP. Works in bash, not sh/dash.
            (exec 3<>"/dev/tcp/${host}/${port}") >/dev/null 2>&1 && { printf ' ok\n'; return 0; }
        fi

        now="$(date +%s)"
        elapsed=$(( now - start ))
        if (( elapsed >= timeout )); then
            printf ' timed out after %ss\n' "$timeout" >&2
            return 1
        fi
        printf '.'
        sleep 1
    done
}

# myip -- print your public IP. Needs curl. I use it more than I'd like to admit.
myip() {
    if ! command -v curl >/dev/null 2>&1; then
        echo "curl not found" >&2; return 127
    fi
    # ifconfig.me is reliable enough; fall back if it's slow or down
    curl -fsS --max-time 5 https://ifconfig.me 2>/dev/null \
        || curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null \
        || { echo "could not determine public IP" >&2; return 1; }
    echo
}

# localip -- first non-loopback IPv4 on the machine.
localip() {
    if command -v ip >/dev/null 2>&1; then
        ip -4 addr show scope global | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1
    elif command -v ifconfig >/dev/null 2>&1; then
        # macOS / BSD
        ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}'
    else
        echo "no 'ip' or 'ifconfig' found" >&2; return 127
    fi
}

# ports -- listening TCP ports with the owning process. Needs ss (or netstat).
# Replaces the old `netstat -tulpn` which is deprecated on modern Linux.
ports() {
    if command -v ss >/dev/null 2>&1; then
        ss -tulpn
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tulpn
    else
        echo "neither 'ss' nor 'netstat' found" >&2; return 127
    fi
}

# httphead <url> -- status code + response headers, follows nothing.
# Usage: httphead https://example.com
httphead() {
    local url="${1:-}"
    [[ -z "$url" ]] && { echo "usage: httphead <url>" >&2; return 2; }
    if ! command -v curl >/dev/null 2>&1; then echo "curl not found" >&2; return 127; fi
    curl -sS -o /dev/null -D - --max-time 10 "$url"
}

# httpcode <url> -- just the status code. Quiet, good for scripts.
# Usage: httpcode https://example.com/api/health
httpcode() {
    local url="${1:-}"
    [[ -z "$url" ]] && { echo "usage: httpcode <url>" >&2; return 2; }
    curl -s -o /dev/null -w '%{http_code}\n' --max-time 10 "$url"
}

# serve [port] [dir] -- quick static file server. Port defaults to 8000.
# Usage: serve 9000 ./public
serve() {
    local port="${1:-8000}"
    local dir="${2:-.}"
    if command -v python3 >/dev/null 2>&1; then
        ( cd "$dir" && python3 -m http.server "$port" )
    elif command -v python >/dev/null 2>&1; then
        ( cd "$dir" && python -m SimpleHTTPServer "$port" )
    else
        echo "no python found" >&2; return 127
    fi
}

# pingg <host> -- 5 quick pings, no flood. Prints a one-line summary.
pingg() {
    local host="${1:-}"
    [[ -z "$host" ]] && { echo "usage: pingg <host>" >&2; return 2; }
    ping -c 5 "$host" 2>&1 | tail -n 2
}

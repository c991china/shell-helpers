# system-helpers.sh -- source me, don't execute me.
# Local system conveniences: disk, processes, archives.

# shellcheck shell=bash

# duf [path] -- disk usage of a directory's immediate children, sorted, human
# readable. Like `du -sh *` but it doesn't choke on huge trees and it sorts.
# Usage: duf /var/log
duf() {
    local path="${1:-.}"
    if ! du --version 2>/dev/null | grep -q GNU; then
        echo "duf needs GNU du (on macOS: brew install coreutils, then use gdu)" >&2
        return 1
    fi
    du -h --max-depth=1 "$path" 2>/dev/null | sort -hr
}

# psg <pattern> -- ps aux filtered by pattern, excluding the grep itself.
# Usage: psg nginx
psg() {
    local pat="${1:-}"
    [[ -z "$pat" ]] && { echo "usage: psg <pattern>" >&2; return 2; }
    ps aux | grep -i -- "$pat" | grep -v grep
}

# topcpu [n] -- top N processes by CPU. Default 10.
topcpu() {
    local n="${1:-10}"
    ps -eo pid,ppid,pcpu,pmem,comm --sort=-pcpu | head -n $(( n + 1 ))
}

# topmem [n] -- top N processes by memory. Default 10.
topmem() {
    local n="${1:-10}"
    ps -eo pid,ppid,pcpu,pmem,rss,comm --sort=-rss | head -n $(( n + 1 ))
}

# killport <port> -- find and kill whatever is listening on a port.
# Asks before killing. Usage: killport 3000
killport() {
    local port="${1:-}"
    [[ -z "$port" ]] && { echo "usage: killport <port>" >&2; return 2; }
    local pids
    if command -v ss >/dev/null 2>&1; then
        pids="$(ss -tulpn 2>/dev/null | awk -v p=":$port" '$5 ~ p {print $NF}' \
            | grep -o 'pid=[0-9]*' | cut -d= -f2 | sort -u)"
    else
        pids="$(lsof -ti tcp:"$port" 2>/dev/null)"
    fi
    [[ -z "$pids" ]] && { echo "nothing listening on port $port"; return 0; }

    echo "Processes on port $port:"
    # shellcheck disable=SC2086
    ps -p $(echo "$pids" | tr '\n' ',') -o pid,user,comm 2>/dev/null || true
    read -r -p "Kill them? [y/N] " ans
    case "$ans" in
        y|Y) echo "$pids" | xargs -r kill ;;
        *) echo "aborted" ;;
    esac
}

# extract <archive> -- unpack anything by extension. One function, all formats.
# Usage: extract archive.tar.gz
extract() {
    local f="${1:-}"
    [[ -z "$f" ]] && { echo "usage: extract <archive>" >&2; return 2; }
    [[ -f "$f" ]] || { echo "no such file: $f" >&2; return 1; }

    case "$f" in
        *.tar.bz2|*.tbz2) tar xjf "$f" ;;
        *.tar.gz|*.tgz)   tar xzf "$f" ;;
        *.tar.xz|*.txz)   tar xJf "$f" ;;
        *.tar.zst)        tar --zstd -xf "$f" ;;
        *.tar)            tar xf "$f" ;;
        *.zip)            unzip -q "$f" ;;
        *.gz)             gunzip -k "$f" ;;
        *.bz2)            bunzip2 -k "$f" ;;
        *.xz)             unxz -k "$f" ;;
        *.7z)             7z x "$f" ;;
        *.rar)            unrar x "$f" ;;
        *) echo "don't know how to extract: $f" >&2; return 1 ;;
    esac
}

# mkcd <dir> -- make a directory and cd into it. Classic.
mkcd() {
    local d="${1:-}"
    [[ -z "$d" ]] && { echo "usage: mkcd <dir>" >&2; return 2; }
    mkdir -p -- "$d" && cd "$d" || return 1
}

# pathadd <dir> -- prepend a dir to PATH if it exists and isn't already there.
# Usage: pathadd ~/.local/bin
pathadd() {
    local d="${1:-}"
    [[ -z "$d" ]] && { echo "usage: pathadd <dir>" >&2; return 2; }
    [[ -d "$d" ]] || { echo "not a directory: $d" >&2; return 1; }
    case ":$PATH:" in
        *":$d:"*) return 0 ;;   # already present
        *) PATH="$d:$PATH"; export PATH ;;
    esac
}

# now -- timestamp for logs. `echo "$(now) starting build"`.
now() { date +'%Y-%m-%d %H:%M:%S'; }

# sizeof <path> -- human readable size. `du -sh` works on GNU and BSD alike.
sizeof() {
    local t="${1:-}"
    [[ -z "$t" ]] && { echo "usage: sizeof <path>" >&2; return 2; }
    du -sh -- "$t"
}

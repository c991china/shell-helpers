# docker-helpers.sh -- source me, don't execute me.
# Docker convenience functions. All wrap `docker` and add no magic.
#
# Guard: these files are sourced. Never put `set -euo pipefail` here.

# shellcheck shell=bash

_docker_has() { command -v docker >/dev/null 2>&1; }

# dsh <container> [shell] -- exec into a running container.
# Picks bash if present, else sh. Usage: dsh my-api
dsh() {
    if ! _docker_has; then echo "docker not found on PATH" >&2; return 127; fi
    local c="${1:-}"
    [[ -z "$c" ]] && { echo "usage: dsh <container> [shell]" >&2; return 2; }
    local sh="${2:-}"
    if [[ -z "$sh" ]]; then
        # prefer bash, fall back to sh; test inside the container
        if docker exec "$c" sh -c 'command -v bash' >/dev/null 2>&1; then
            sh=bash
        else
            sh=sh
        fi
    fi
    docker exec -it "$c" "$sh"
}

# dlog <container> [lines] -- follow logs with a sane tail default.
# Usage: dlog my-api 200
dlog() {
    local c="${1:-}"
    local n="${2:-100}"
    [[ -z "$c" ]] && { echo "usage: dlog <container> [lines=100]" >&2; return 2; }
    docker logs -f --tail "$n" "$c"
}

# dstopall [--force] -- stop every running container. Asks first.
# Usage: dstopall
dstopall() {
    if ! _docker_has; then echo "docker not found on PATH" >&2; return 127; fi
    local ids
    ids="$(docker ps -q)"
    if [[ -z "$ids" ]]; then echo "no running containers"; return 0; fi
    local count
    count="$(echo "$ids" | wc -l | tr -d ' ')"
    read -r -p "Stop $count running container(s)? [y/N] " ans
    case "$ans" in
        y|Y) ;;
        *) echo "aborted"; return 0 ;;
    esac
    # shellcheck disable=SC2086
    docker stop $ids
}

# dclean -- remove stopped containers and dangling images. Not volumes.
# Safe-ish: dangling images are the untagged ones from old builds.
dclean() {
    if ! _docker_has; then echo "docker not found on PATH" >&2; return 127; fi
    echo "Removing stopped containers..."
    docker container prune -f
    echo "Removing dangling images (untagged)..."
    docker image prune -f
    echo
    echo "Disk usage after cleanup:"
    docker system df
    echo
    echo "NOTE: volumes were NOT touched. To remove unused volumes:"
    echo "  docker volume prune       # this deletes data, read the prompt"
}

# dip <container> -- show the container's IP on its default network.
# Handy when you need to curl a service from the host but the port isn't published.
dip() {
    local c="${1:-}"
    [[ -z "$c" ]] && { echo "usage: dip <container>" >&2; return 2; }
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$c"
}

# dsize -- human-readable sizes of running containers' writable layers.
dsize() {
    docker ps --size --format 'table {{.Names}}\t{{.Size}}\t{{.Status}}'
}

# dex <container> <src> <dest> -- copy a file out of a container.
# dex my-api:/app/logs/error.log ./error.log
dex() {
    [[ $# -ne 3 ]] && { echo "usage: dex <container>:<src> <dest>" >&2; return 2; }
    docker cp "$1" "$2"
}

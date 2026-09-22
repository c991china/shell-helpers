# git-helpers.sh -- source me, don't execute me.
# Git conveniences that don't exist as a one-liner alias.
# Functions here are interactive (prompt) or do multiple steps.

# shellcheck shell=bash

# groot -- cd to the root of the current git repo. Works from any subdir.
groot() {
    local root
    root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
        echo "not inside a git repo" >&2; return 1;
    }
    cd "$root" || return 1
}

# gwip [message] -- "work in progress" commit of everything. No hooks, no fuss.
# Meant for temporary saves; squash it away later. Usage: gwip
gwip() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        echo "not inside a git repo" >&2; return 1;
    }
    git add -A
    git commit --no-verify -m "WIP: ${*:-snapshot}"
}

# gprune -- delete local branches whose upstream is gone (merged + deleted on
# the remote). This is the one people forget exists.
gprune() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        echo "not inside a git repo" >&2; return 1;
    }
    echo "Fetching with prune..."
    git fetch -p || return 1

    # branches with a gone upstream
    local gone
    gone="$(git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads \
        | awk '$2 == "[gone]" {print $1}')"

    if [[ -z "$gone" ]]; then
        echo "No branches with a gone upstream. Nothing to prune."
        return 0
    fi

    echo "Branches with deleted upstreams:"
    echo "$gone" | sed 's/^/  /'
    read -r -p "Delete these? [y/N] " ans
    case "$ans" in
        y|Y) ;;
        *) echo "aborted"; return 0 ;;
    esac
    # -d not -D: refuse to delete anything not fully merged.
    echo "$gone" | xargs -r git branch -d
}

# gwt <path> [branch] -- create a worktree. New branch if it doesn't exist,
# existing branch if it does. Usage: gwt ../hotfix main
gwt() {
    local path="${1:-}"
    local branch="${2:-}"
    [[ -z "$path" ]] && { echo "usage: gwt <path> [branch]" >&2; return 2; }
    if [[ -z "$branch" ]]; then
        git worktree add "$path"
        return
    fi
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        git worktree add "$path" "$branch"
    else
        git worktree add -b "$branch" "$path"
    fi
}

# gwtclean -- remove worktrees whose directories are gone, then prune.
gwtclean() {
    echo "Current worktrees:"
    git worktree list
    echo
    git worktree prune -v
    echo "pruned."
}

# gbclean [main] -- delete local branches merged into <main> (default: main).
# Skips the current branch and common protected names. Asks first.
gbclean() {
    local main="${1:-main}"
    git show-ref --verify --quiet "refs/heads/$main" || {
        echo "no local branch '$main' (pass one: gbclean <branch>)" >&2; return 1;
    }
    local current
    current="$(git symbolic-ref --short HEAD 2>/dev/null)"
    local merged
    merged="$(git branch --merged "$main" --format '%(refname:short)' \
        | grep -Ev '^(main|master|develop|release/.*)$' \
        | grep -Fvx "$current" || true)"

    [[ -z "$merged" ]] && { echo "nothing merged into $main to clean"; return 0; }

    echo "Merged into $main:"
    echo "$merged" | sed 's/^/  /'
    read -r -p "Delete these? [y/N] " ans
    case "$ans" in
        y|Y) echo "$merged" | xargs -r git branch -d ;;
        *) echo "aborted" ;;
    esac
}

# gwho <path> -- who last touched a file, and when. Usage: gwho src/app.py
gwho() {
    local f="${1:-}"
    [[ -z "$f" ]] && { echo "usage: gwho <file>" >&2; return 2; }
    git log -1 --format='%h %an <%ae> %ad%n%s' --date=relative -- "$f"
}

# gurl -- print the web URL of origin, so you can open it. Handles ssh remotes.
gurl() {
    local remote
    remote="$(git remote get-url origin 2>/dev/null)" || {
        echo "no 'origin' remote" >&2; return 1;
    }
    # git@github.com:user/repo.git -> https://github.com/user/repo
    remote="${remote%.git}"
    remote="${remote#git@}"
    remote="${remote/:/\/}"
    case "$remote" in
        http*) echo "$remote" ;;
        *)     echo "https://$remote" ;;
    esac
}

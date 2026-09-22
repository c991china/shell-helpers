#!/usr/bin/env bash
#
# bashrc_snippet.sh -- the block that gets sourced from your shell rc.
#
# You normally don't run this directly. install.sh appends a line to ~/.bashrc
# (or ~/.zshrc) that sources this file. You can also paste this whole file into
# your rc by hand if you'd rather not have install.sh touch it.
#
# This file is meant to be SOURCED. Do not add `set -e` here.

# Directory holding the helpers. Defaults to ~/.shell-helpers, override by
# exporting SHELL_HELPERS_DIR before this is sourced.
SHELL_HELPERS_DIR="${SHELL_HELPERS_DIR:-$HOME/.shell-helpers}"

if [[ -d "$SHELL_HELPERS_DIR" ]]; then
    for _sh_file in \
        docker-helpers.sh \
        network-helpers.sh \
        git-helpers.sh \
        system-helpers.sh \
        k8s-helpers.sh
    do
        if [[ -r "$SHELL_HELPERS_DIR/$_sh_file" ]]; then
            # shellcheck source=/dev/null
            source "$SHELL_HELPERS_DIR/$_sh_file"
        fi
    done
    unset _sh_file
else
    printf 'shell-helpers: %s not found, skipping\n' "$SHELL_HELPERS_DIR" >&2
fi

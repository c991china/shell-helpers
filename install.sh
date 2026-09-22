#!/usr/bin/env bash
#
# install.sh -- wire shell-helpers into your shell rc.
#
# Appends a source line to ~/.bashrc (or ~/.zshrc under zsh), wrapped in marker
# comments so running this twice does not add the block twice. Does not modify
# anything else.
#
#   ./install.sh                 # detect rc from $SHELL
#   ./install.sh --zsh           # force zsh rc
#   SHELL_HELPERS_DIR=/path ./install.sh
#
# Uninstall: delete the block between the markers (it prints the exact lines).

set -euo pipefail

HELPERS_DIR="${SHELL_HELPERS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
MARKER_BEGIN="# >>> shell-helpers >>>"
MARKER_END="# <<< shell-helpers <<<"

RC_FILE=""
case "${1:-}" in
    --zsh) RC_FILE="$HOME/.zshrc" ;;
    --bash) RC_FILE="$HOME/.bashrc" ;;
    --help|-h)
        sed -n '2,16p' "$0"; exit 0 ;;
    "")
        case "${SHELL:-}" in
            *zsh) RC_FILE="$HOME/.zshrc" ;;
            *)    RC_FILE="$HOME/.bashrc" ;;
        esac
        ;;
    *)
        echo "unknown arg: $1" >&2; exit 2 ;;
esac

[[ -f "$HELPERS_DIR/bashrc_snippet.sh" ]] || {
    echo "error: $HELPERS_DIR/bashrc_snippet.sh not found" >&2
    echo "run this from the repo dir, or set SHELL_HELPERS_DIR" >&2
    exit 1
}

# Create the rc if it doesn't exist (fresh machines).
[[ -f "$RC_FILE" ]] || { touch "$RC_FILE"; echo "created $RC_FILE"; }

if grep -qF "$MARKER_BEGIN" "$RC_FILE"; then
    echo "Already installed in $RC_FILE (found the marker). Nothing to do."
    echo "Remove these two lines to reinstall:"
    echo "  $MARKER_BEGIN"
    echo "  $MARKER_END"
    exit 0
fi

{
    echo ""
    echo "$MARKER_BEGIN"
    echo "# added by shell-helpers/install.sh on $(date +%Y-%m-%d)"
    echo "export SHELL_HELPERS_DIR=\"$HELPERS_DIR\""
    echo "[ -r \"\$SHELL_HELPERS_DIR/bashrc_snippet.sh\" ] && source \"\$SHELL_HELPERS_DIR/bashrc_snippet.sh\""
    echo "$MARKER_END"
} >> "$RC_FILE"

echo "Installed. Added a source block to $RC_FILE:"
echo "  helpers dir: $HELPERS_DIR"
echo
echo "Load it now with:  source $RC_FILE"
echo "Or open a new shell."

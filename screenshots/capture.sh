#!/usr/bin/env bash
# Capture the README showcase screenshots into ./screenshots/ with the
# filenames referenced by README.md. Run from anywhere; output lands next
# to this script.
#
# Targets (skip any with --only=name1,name2):
#   desktop              full workspace
#   noctalia-launcher    Mod+Space surface
#   noctalia-control     Mod+S surface
#   nvim                 a Neovim window
#   terminal             a kitty window with fastfetch
#
# Requires: grim, niri, qs (Quickshell, for Noctalia toggles).

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
DELAY="${DELAY:-3}"
ONLY=""

for arg in "$@"; do
    case "$arg" in
        --only=*) ONLY="${arg#--only=}" ;;
        --delay=*) DELAY="${arg#--delay=}" ;;
        -h|--help)
            awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "$0"
            exit 0
            ;;
        *) echo "unknown arg: $arg" >&2; exit 2 ;;
    esac
done

want() {
    [[ -z "$ONLY" ]] && return 0
    [[ ",$ONLY," == *",$1,"* ]]
}

countdown() {
    for ((i = DELAY; i > 0; i--)); do
        printf '\r  capturing in %ds... ' "$i"
        sleep 1
    done
    printf '\r                          \r'
}

shot() {
    local name="$1" prompt="$2"
    want "$name" || return 0
    printf '\n• %s\n  %s\n  press enter when ready' "$name" "$prompt"
    read -r
    countdown
    grim "$SCRIPT_DIR/$name.png"
    printf '  saved %s\n' "$name.png"
}

noctalia_toggle() {
    qs -c noctalia-shell ipc call "$1" toggle >/dev/null 2>&1 || true
}

shot desktop "clear overlays — no popups, no notifications"

if want noctalia-launcher; then
    noctalia_toggle launcher
    shot noctalia-launcher "launcher should be open (toggling now)"
    noctalia_toggle launcher
fi

if want noctalia-control; then
    noctalia_toggle controlCenter
    shot noctalia-control "control center should be open (toggling now)"
    noctalia_toggle controlCenter
fi

shot nvim "focus a nvim window with something interesting on screen"
shot terminal "focus a kitty window with fastfetch / a useful view"

printf '\nDone. Files in %s\n' "$SCRIPT_DIR"

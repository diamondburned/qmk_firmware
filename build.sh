#!/usr/bin/env nix-shell
#!nix-shell -i bash -p qmk jq
set -eo pipefail

main() {
    local keyboard="$1"
    local keymap="${2:-default}"

    if [[ -z "$keyboard" ]]; then
        log "usage: $0 <keyboard> [<keymap>]"
        return 1
    fi

    keymap_compile::ensure "$keyboard" "$keymap"
    build "$keyboard" "$keymap"
}

# build <keyboard> <keymap>
build() {
    local keyboard="$1"
    local keymap="$2"

    case "$keyboard" in
    "atreus62")
        make atreus62:"$keymap":dfu-util CTPC=yes
        ;;
    "corne"|"crkbd")
        make crkbd/r2g:"$keymap"
        # qmk flash -kb crkbd/r2g -km "$keymap"
        ;;
    *)
        printf "unknown keyboard %q" "$keyboard"
        ;;
    esac
}

# keymap_compile::ensure <keyboard> <keymap>
keymap_compile::ensure() {
    local keyboard="$1"
    local keymap="$2"

    (
        cd keyboards/"$keyboard"/keymaps/"$keymap" || {
            log "keymap $keymap not found for keyboard $keyboard"
            return 1
        }

        if [[ -f keymap.json ]]; then
            log "detected keymap.json for $keyboard/$keymap, generating keymap.c"
            keymap_compile::compile
        fi
    )
}

# keymap_compile::compile
#
# Compile keymap.json to keymap.c in the same directory.
keymap_compile::compile() {
	nlayers=$(jq -r '.layers | length' keymap.json)
	layout=$(jq -r '.layout' keymap.json)

    {
	cat<<'EOF'
#include QMK_KEYBOARD_H
#include <stdio.h>

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
EOF

	for ((i = 0; i < nlayers; i++)); {
        printf "  [%s] = %s(\n" "$i" "$layout"
        printf "    " && jq -r ".layers[$i] | join(\", \")" keymap.json
        printf "  ),"
	}

	cat<<'EOF'
};
EOF
    } > keymap.c
}

log() {
    echo "$@" >&2
}

main "$@"

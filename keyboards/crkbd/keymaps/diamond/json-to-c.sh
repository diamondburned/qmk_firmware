#!/usr/bin/env bash
convert() {
	nlayers=$(jq -r '.layers | length' keymap.json)
	layout=$(jq -r '.layout' keymap.json)

	cat<<'EOF'
#include QMK_KEYBOARD_H

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
EOF
	
	for ((i = 0; i < nlayers; i++)); {
		echo "[$i] = ${layout}("
		jq -r ".layers[$i] | join(\", \")" keymap.json
		echo "),"
	}

	cat<<'EOF'
};
EOF
}

fmt() {
	command -v clang-format &> /dev/null && clang-format || cat
}

main() {
	out="keymap.h"
	[[ "$1" ]] && out="$1"
	convert | fmt > "$out"
}

main "$@"

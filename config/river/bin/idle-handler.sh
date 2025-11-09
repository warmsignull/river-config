#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="${HOME}/.config/river"
BIN_DIR="${CONFIG_DIR}/bin"

# shellcheck disable=SC1091
source "${BIN_DIR}/river-lib.sh"

if ! rc_command_exists swayidle; then
	rc_debug_note "swayidle not available, skipping idle handler."
	exit 0
fi

swayidle -w \
	timeout 600 "${BIN_DIR}/river-controls.sh lock immediate" \
	timeout 605 "${BIN_DIR}/river-controls.sh display off" \
	resume "${BIN_DIR}/river-controls.sh display on"

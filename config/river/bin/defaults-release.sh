#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="${HOME}/.config/river"
BIN_DIR="${CONFIG_DIR}/bin"
RUNTIME_DIR="${CONFIG_DIR}/state/runtime"
mkdir -p "${RUNTIME_DIR}"

if [ -f "${RUNTIME_DIR}/defaults_used" ]; then
	rm -f "${RUNTIME_DIR}/defaults_used"
else
	"${BIN_DIR}/river-controls.sh" debug toggle
fi

rm -f "${RUNTIME_DIR}/defaults_active"
riverctl enter-mode normal

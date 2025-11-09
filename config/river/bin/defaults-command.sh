#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="${HOME}/.config/river"
RUNTIME_DIR="${CONFIG_DIR}/state/runtime"
BIN_DIR="${CONFIG_DIR}/bin"
mkdir -p "${RUNTIME_DIR}"

"${BIN_DIR}/river-controls.sh" defaults "$@"
touch "${RUNTIME_DIR}/defaults_used"
riverctl enter-mode normal

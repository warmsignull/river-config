#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="${HOME}/.config/river"
BIN_DIR="${CONFIG_DIR}/bin"

"${BIN_DIR}/river-controls.sh" "$@"
riverctl enter-mode normal

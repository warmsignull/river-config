#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="${HOME}/.config/river"
RUNTIME_DIR="${CONFIG_DIR}/state/runtime"
mkdir -p "${RUNTIME_DIR}"

rm -f "${RUNTIME_DIR}/defaults_used"
touch "${RUNTIME_DIR}/defaults_active"

riverctl enter-mode defaults

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/install-packages.sh"
"${SCRIPT_DIR}/install-config.sh"

echo "==> Installation complete"
echo "Start river with 'river' from a Wayland-compatible login manager or tty."

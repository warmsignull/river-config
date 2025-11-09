#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CONFIG_SOURCE="${REPO_ROOT}/config/river"
CONFIG_TARGET="${HOME}/.config/river"

echo "==> Deploying River configuration into ${CONFIG_TARGET}"
mkdir -p "${CONFIG_TARGET}"

if [ -d "${CONFIG_TARGET}" ] && [ "$(ls -A "${CONFIG_TARGET}")" ]; then
	BACKUP_PATH="${CONFIG_TARGET}.$(date +%Y%m%d%H%M%S).bak"
	echo "Backing up existing configuration to ${BACKUP_PATH}"
	cp -a -- "${CONFIG_TARGET}" "${BACKUP_PATH}"
fi

cp -a -- "${CONFIG_SOURCE}/." "${CONFIG_TARGET}/"

chmod +x "${CONFIG_TARGET}/init"
find "${CONFIG_TARGET}/bin" -type f -exec chmod +x {} \;

echo "==> Configuration installed."

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

# Normalise state to ensure key defaults are consistent.
CONFIG_DIR="${CONFIG_TARGET}"
BIN_DIR="${CONFIG_TARGET}/bin"
STATE_DIR="${CONFIG_TARGET}/state"
STATE_FILE="${STATE_DIR}/settings.env"
mkdir -p "${STATE_DIR}"
if [ -f "${BIN_DIR}/river-lib.sh" ]; then
	# shellcheck disable=SC1091
	source "${BIN_DIR}/river-lib.sh"
	ensure_state
	state_set launcher "wofi"
	state_set terminal "foot"
	state_set last_workspace "1"
else
	touch "${STATE_FILE}"
	if ! grep -q '^launcher=' "${STATE_FILE}"; then
		printf 'launcher=%s\n' "wofi" >>"${STATE_FILE}"
	else
		sed -i 's/^launcher=.*/launcher=wofi/' "${STATE_FILE}"
	fi
	if ! grep -q '^terminal=' "${STATE_FILE}"; then
		printf 'terminal=%s\n' "foot" >>"${STATE_FILE}"
	else
		sed -i 's/^terminal=.*/terminal=foot/' "${STATE_FILE}"
	fi
	if ! grep -q '^last_workspace=' "${STATE_FILE}"; then
		printf 'last_workspace=%s\n' "1" >>"${STATE_FILE}"
	else
		sed -i 's/^last_workspace=.*/last_workspace=1/' "${STATE_FILE}"
	fi
fi

echo "==> Configuration installed."

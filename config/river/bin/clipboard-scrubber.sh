#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="${HOME}/.config/river"
BIN_DIR="${CONFIG_DIR}/bin"

# shellcheck disable=SC1091
source "${BIN_DIR}/river-lib.sh"

ensure_state

timeout_minutes="$(state_get clipboard_timeout_minutes 15)"
timeout_seconds=$((timeout_minutes * 60))

if ! rc_command_exists wl-paste || ! rc_command_exists wl-copy; then
	rc_debug_note "Clipboard scrubber skipped (wl-clipboard not available)."
	exit 0
fi

prev_hash=""
last_change=0

while true; do
	now="$(date +%s)"
	if wl-paste -l >/dev/null 2>&1; then
		current_data="$(wl-paste -n)"
		current_hash="$(printf '%s' "${current_data}" | sha256sum | cut -d' ' -f1)"
	else
		current_hash=""
	fi

	if [ "${current_hash}" != "${prev_hash}" ]; then
		prev_hash="${current_hash}"
		last_change="${now}"
	fi

	if [ -n "${current_hash}" ] && [ "${current_hash}" = "${prev_hash}" ]; then
		if [ $((now - last_change)) -ge "${timeout_seconds}" ]; then
			wl-copy --clear
			rc_notify "low" "Clipboard Cleared" "Clipboard cleared after ${timeout_minutes} minutes." "0"
			prev_hash=""
			last_change="${now}"
		fi
	fi

	sleep 5
done

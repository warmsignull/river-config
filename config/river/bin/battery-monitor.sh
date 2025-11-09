#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="${HOME}/.config/river"
BIN_DIR="${CONFIG_DIR}/bin"

# shellcheck disable=SC1091
source "${BIN_DIR}/river-lib.sh"

ensure_state

BATTERY_PATH="$(find /sys/class/power_supply -maxdepth 1 -type d -name 'BAT*' | head -n1)"
if [ -z "${BATTERY_PATH}" ]; then
	exit 0
fi

alerted=0
while true; do
	if [ ! -f "${BATTERY_PATH}/capacity" ]; then
		sleep 60
		continue
	fi

	capacity="$(cat "${BATTERY_PATH}/capacity")"
	status="Unknown"
	if [ -f "${BATTERY_PATH}/status" ]; then
		status="$(cat "${BATTERY_PATH}/status")"
	fi
	threshold="$(state_get battery_threshold 20)"

	if [ "${capacity}" -le "${threshold}" ] && [ "${status}" != "Charging" ]; then
		if [ "${alerted}" -eq 0 ]; then
			rc_notify "critical" "Battery Low" "Battery at ${capacity}%%. Plug in to avoid suspend." "1"
			if rc_command_exists brightnessctl; then
				brightnessctl set 40% >/dev/null 2>&1 || true
			fi
			alerted=1
		fi
	else
		alerted=0
	fi

	sleep 60
done

#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="${HOME}/.config/river"
BIN_DIR="${CONFIG_DIR}/bin"

# shellcheck disable=SC1091
source "${BIN_DIR}/river-lib.sh"

ensure_state

MODE="${1:-toggle}"
SCOPE="${2:-full}"
pid_file="${RUNTIME_DIR}/recording.pid"
output_dir="${HOME}/Videos/Recordings"
mkdir -p "${output_dir}"

stop_recording() {
	if [ -f "${pid_file}" ]; then
		pid="$(cat "${pid_file}")"
		if kill -0 "${pid}" >/dev/null 2>&1; then
			kill "${pid}" >/dev/null 2>&1 || true
			rc_notify "normal" "Screen Recording" "Recording stopped and saved." "0"
		fi
		rm -f "${pid_file}"
	fi
}

start_recording() {
	if ! rc_command_exists wf-recorder; then
		rc_notify "normal" "Screen Recording" "wf-recorder missing." "1"
		exit 1
	fi

	timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
	file="${output_dir}/recording_${timestamp}.mp4"

	case "${SCOPE}" in
	full)
		wf-recorder -f "${file}" &
		;;
	area)
		if ! rc_command_exists slurp; then
			rc_notify "normal" "Screen Recording" "slurp missing for area capture." "1"
			exit 1
		fi
		region="$(slurp)"
		wf-recorder -g "${region}" -f "${file}" &
		;;
	window)
		if ! rc_command_exists slurp; then
			rc_notify "normal" "Screen Recording" "slurp missing for window capture." "1"
			exit 1
		fi
		region="$(slurp -r)"
		wf-recorder -g "${region}" -f "${file}" &
		;;
	esac

	rec_pid=$!
	disown "${rec_pid}" 2>/dev/null || true
	printf '%s\n' "${rec_pid}" >"${pid_file}"
	rc_notify "normal" "Screen Recording" "Recording started (${SCOPE})." "0"
}

case "${MODE}" in
stop)
	stop_recording
	;;
start)
	start_recording
	;;
toggle)
	if [ -f "${pid_file}" ]; then
		pid="$(cat "${pid_file}")"
		if kill -0 "${pid}" >/dev/null 2>&1; then
			stop_recording
		else
			start_recording
		fi
	else
		start_recording
	fi
	;;
esac

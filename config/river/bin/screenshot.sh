#!/usr/bin/env bash

set -euo pipefail

MODE="${1:-full}"
OUTPUT_DIR="${HOME}/Pictures/Screenshots"
mkdir -p "${OUTPUT_DIR}"

timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
file="${OUTPUT_DIR}/screenshot_${timestamp}.png"

case "${MODE}" in
full)
	if command -v grim >/dev/null 2>&1; then
		grim "${file}"
	else
		echo "grim not installed" >&2
		exit 1
	fi
	;;
area)
	if command -v grim >/dev/null 2>&1 && command -v slurp >/dev/null 2>&1; then
		region="$(slurp)"
		grim -g "${region}" "${file}"
	else
		echo "grim/slurp not installed" >&2
		exit 1
	fi
	;;
window)
	if command -v grim >/dev/null 2>&1 && command -v slurp >/dev/null 2>&1; then
		region="$(slurp -r)"
		grim -g "${region}" "${file}"
	else
		echo "grim/slurp not installed" >&2
		exit 1
	fi
	;;
esac

if command -v wl-copy >/dev/null 2>&1; then
	wl-copy <"${file}"
fi

if command -v notify-send >/dev/null 2>&1; then
	notify-send "Screenshot saved" "${file}"
fi

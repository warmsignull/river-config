#!/usr/bin/env bash

set -euo pipefail

# Determine repository root from script location.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

PACMAN_PACKAGES=(
	river
	rivertile
	waybar
	swaybg
	foot
	fuzzel
	thunar
	mako
	brightnessctl
	pamixer
	wl-clipboard
)

CONFIG_TARGET="${HOME}/.config/river"
CONFIG_SOURCE="${REPO_ROOT}/config/river"

echo "==> Installing dependencies via pacman"
if ! command -v sudo >/dev/null 2>&1; then
	echo "error: sudo is required to install packages." >&2
	exit 1
fi

sudo pacman -S --needed "${PACMAN_PACKAGES[@]}"

echo "==> Deploying river configuration"
mkdir -p -- "${CONFIG_TARGET}"

if [ -f "${CONFIG_TARGET}/init" ] && [ ! -L "${CONFIG_TARGET}/init" ]; then
	BACKUP_PATH="${CONFIG_TARGET}/init.$(date +%Y%m%d%H%M%S).bak"
	echo "Backing up existing init to ${BACKUP_PATH}"
	cp -- "${CONFIG_TARGET}/init" "${BACKUP_PATH}"
fi

ln -sf -- "${CONFIG_SOURCE}/init" "${CONFIG_TARGET}/init"

echo "==> Installation complete"
echo "Start river with 'river' from a Wayland-compatible login manager or tty."

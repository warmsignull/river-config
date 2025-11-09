#!/usr/bin/env bash

set -euo pipefail

PACMAN_PACKAGES=(
	river
	waybar
	nwg-panel
	mako
	fuzzel
	wofi
	bemenu
	foot
	kitty
	alacritty
	wezterm
	pavucontrol
	helvum
	swaybg
	swww
	brightnessctl
	pamixer
	wl-clipboard
	grim
	slurp
	wf-recorder
	swayidle
	swaylock
	gtklock
	waylock
	swayosd
	xdg-desktop-portal
	xdg-desktop-portal-wlr
	xdg-desktop-portal-gtk
	pipewire
	wireplumber
	xdg-user-dirs
	libnotify
	pulseaudio-alsa
	upower
	qt5ct
	qt6ct
	kvantum
	btop
	seatd
)

AUR_PACKAGES=(
	rivertile
	yambar
	tofi
	swaylock-effects
	wlopm
	ags
	eww
)

echo "==> Installing core packages via pacman"
if ! command -v sudo >/dev/null 2>&1; then
	echo "error: sudo is required to install packages." >&2
	exit 1
fi

sudo pacman -S --needed "${PACMAN_PACKAGES[@]}"

if command -v paru >/dev/null 2>&1; then
	echo "==> Installing optional AUR packages via paru"
	paru -S --needed "${AUR_PACKAGES[@]}"
elif command -v yay >/dev/null 2>&1; then
	echo "==> Installing optional AUR packages via yay"
	yay -S --needed "${AUR_PACKAGES[@]}"
else
	echo "==> AUR helpers not found. Consider installing these manually:"
	printf '   %s\n' "${AUR_PACKAGES[@]}"
fi

#!/usr/bin/env bash

set -euo pipefail

# Configure system-wide dark theme preferences where possible.

if command -v gsettings >/dev/null 2>&1; then
	gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 || true
	gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' >/dev/null 2>&1 || true
	gsettings set org.gnome.desktop.interface icon-theme 'Adwaita-dark' >/dev/null 2>&1 || true
	gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' >/dev/null 2>&1 || true
	gsettings set org.gnome.desktop.interface font-name 'Inter 11' >/dev/null 2>&1 || true
fi

mkdir -p "${HOME}/.config/gtk-3.0" "${HOME}/.config/gtk-4.0"
cat >"${HOME}/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-font-name=Inter 11
EOF

cat >"${HOME}/.config/gtk-4.0/settings.ini" <<'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-font-name=Inter 11
EOF

mkdir -p "${HOME}/.config/kdeglobals"
cat >"${HOME}/.config/kdeglobals" <<'EOF'
[General]
ColorScheme=BreezeDark
EOF

mkdir -p "${HOME}/.config/qt5ct"
cat >"${HOME}/.config/qt5ct/qt5ct.conf" <<'EOF'
[Appearance]
color_scheme_path=/usr/share/qt5ct/colors/darker.conf
icon_theme=Adwaita-dark
style=kvantum-dark
EOF

mkdir -p "${HOME}/.config/qt6ct"
cat >"${HOME}/.config/qt6ct/qt6ct.conf" <<'EOF'
[Appearance]
color_scheme_path=/usr/share/qt6ct/colors/darker.conf
icon_theme=Adwaita-dark
style=kvantum-dark
EOF

if command -v kvantummanager >/dev/null 2>&1; then
	kvantummanager --set KvAdaptaDark >/dev/null 2>&1 || true
fi

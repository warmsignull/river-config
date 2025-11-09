#!/usr/bin/env bash

# Shared helper library for River configuration scripts.
# Provides state management, notification helpers, and service/application utilities.

set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-${HOME}/.config/river}"
BIN_DIR="${BIN_DIR:-${CONFIG_DIR}/bin}"
STATE_DIR="${STATE_DIR:-${CONFIG_DIR}/state}"
STATE_FILE="${STATE_FILE:-${STATE_DIR}/settings.env}"
RUNTIME_DIR="${RUNTIME_DIR:-${STATE_DIR}/runtime}"

mkdir -p "${STATE_DIR}" "${RUNTIME_DIR}"

declare -A DEFAULTS=(
	[launcher]="fuzzel"
	[notifications_enabled]="1"
	[notification_manager]="mako"
	[terminal]="foot"
	[font_profile]="sans"
	[style_profile]="nord"
	[wallpaper_enabled]="1"
	[panel]="waybar"
	[debug_mode]="0"
	[wallpaper_transitions]="1"
	[privacy_mode]="0"
	[zen_mode]="0"
	[lock_tool]="swaylock"
	[clipboard_timeout_minutes]="15"
	[last_workspace]="1"
	[wallpaper_path]="${HOME}/Pictures/wallpaper.png"
	[widget_system]="eww"
	[battery_threshold]="20"
	[workspace_mode]="tiling"
)

LAUNCHER_OPTIONS=(fuzzel wofi tofi bemenu-run)
TERMINAL_OPTIONS=(foot kitty alacritty wezterm gnome-terminal)
PANEL_OPTIONS=(waybar yambar nwg-panel none)
STYLE_OPTIONS=(nord gruvbox mocha)
FONT_OPTIONS=(sans mono large)
NOTIFICATION_MANAGERS=(mako none)
LOCKER_OPTIONS=(swaylock swaylock-effects gtklock waylock)
WIDGET_SYSTEMS=(eww ags none)

ensure_state() {
	mkdir -p "${STATE_DIR}"
	touch "${STATE_FILE}"
	for key in "${!DEFAULTS[@]}"; do
		if ! grep -q "^${key}=" "${STATE_FILE}"; then
			printf '%s=%s\n' "${key}" "${DEFAULTS[${key}]}" >>"${STATE_FILE}"
		fi
	done
}

state_get() {
	local key="$1"
	local fallback="${2:-}"
	if [ -f "${STATE_FILE}" ]; then
		local line
		line=$(grep -m1 "^${key}=" "${STATE_FILE}" || true)
		if [ -n "${line}" ]; then
			printf '%s\n' "${line#*=}"
			return 0
		fi
	fi
	if [[ -n "${DEFAULTS[$key]+set}" ]]; then
		printf '%s\n' "${DEFAULTS[$key]}"
		return 0
	fi
	printf '%s\n' "${fallback}"
}

state_set() {
	local key="$1"
	local value="$2"
	ensure_state
	if grep -q "^${key}=" "${STATE_FILE}"; then
		tmp="$(mktemp)"
		grep -v "^${key}=" "${STATE_FILE}" >"${tmp}"
		printf '%s=%s\n' "${key}" "${value}" >>"${tmp}"
		cat "${tmp}" >"${STATE_FILE}"
		rm -f "${tmp}"
	else
		printf '%s=%s\n' "${key}" "${value}" >>"${STATE_FILE}"
	fi
}

cycle_value() {
	local key="$1"
	shift
	local options=("$@")
	local current
	current=$(state_get "${key}")
	if [ "${#options[@]}" -eq 0 ]; then
		return 1
	fi
	local next_index=0
	for idx in "${!options[@]}"; do
		if [ "${options[$idx]}" = "${current}" ]; then
			next_index=$(( (idx + 1) % ${#options[@]} ))
			break
		fi
	done
	local new="${options[$next_index]}"
	state_set "${key}" "${new}"
	printf '%s\n' "${new}"
}

rc_command_exists() {
	command -v "$1" >/dev/null 2>&1
}

rc_spawn_once() {
	local process_name="$1"
	shift
	if pgrep -x "${process_name}" >/dev/null 2>&1; then
		return 0
	fi
	("$@") >/dev/null 2>&1 &
	disown
}

rc_kill_if_running() {
	local process_name="$1"
	if pgrep -x "${process_name}" >/dev/null 2>&1; then
		pkill -x "${process_name}"
	fi
}

rc_do_send() {
	local urgency="$1"
	local title="$2"
	local body="$3"
	if rc_command_exists notify-send; then
		notify-send --urgency="${urgency}" "${title}" "${body}"
	elif rc_command_exists makoctl; then
		printf '{"app-name":"River","summary":"%s","body":"%s","urgency":"%s"}\n' "${title}" "${body}" "${urgency}" | makoctl send -
	else
		printf '[%s] %s: %s\n' "${urgency}" "${title}" "${body}" >&2
	fi
}

rc_notify() {
	local urgency="${1:-low}"
	local title="${2:-River}"
	local body="${3:-}"
	local force="${4:-0}"
	local debug="$(state_get debug_mode 0)"
	local enabled="$(state_get notifications_enabled 1)"
	if [ "${force}" = "1" ] || [ "${debug}" = "1" ] || [ "${enabled}" = "1" ]; then
		rc_do_send "${urgency}" "${title}" "${body}"
	fi
}

rc_debug_note() {
	local body="$1"
	if [ "$(state_get debug_mode 0)" = "1" ]; then
		rc_do_send "low" "River Debug" "${body}"
	fi
}

rc_apply_notifications() {
	local enabled
	enabled="$(state_get notifications_enabled 1)"
	local manager
	manager="$(state_get notification_manager mako)"

	case "${manager}" in
	mako)
		if [ "${enabled}" = "1" ]; then
			if rc_command_exists mako; then
				rc_spawn_once "mako" mako
			else
				rc_notify "normal" "River" "Requested notification manager 'mako' is not installed." "1"
			fi
		else
			rc_kill_if_running "mako"
		fi
		;;
	none)
		rc_kill_if_running "mako"
		;;
	esac
}

rc_apply_panel() {
	local panel
	panel="$(state_get panel waybar)"
	for candidate in waybar yambar "nwg-panel" ; do
		rc_kill_if_running "${candidate}"
	done

	case "${panel}" in
	waybar)
		rc_command_exists waybar && rc_spawn_once "waybar" waybar
		;;
	yambar)
		rc_command_exists yambar && rc_spawn_once "yambar" yambar
		;;
	"nwg-panel")
		rc_command_exists nwg-panel && rc_spawn_once "nwg-panel" nwg-panel
		;;
	none)
		;;
	*)
		rc_notify "normal" "River" "Unknown panel '${panel}' requested." "1"
		;;
	esac
}

rc_wallpaper_transition_args() {
	if [ "$(state_get wallpaper_transitions 1)" = "1" ]; then
		printf '%s\n' "--transition-type wipe --transition-fps 60"
	else
		printf '\n'
	fi
}

rc_apply_wallpaper() {
	local enabled
	enabled="$(state_get wallpaper_enabled 1)"
	local transitions
	transitions="$(state_get wallpaper_transitions 1)"
	local wallpaper_path
	wallpaper_path="$(state_get wallpaper_path "${HOME}/Pictures/wallpaper.png")"

	if [ "${enabled}" = "1" ]; then
		if rc_command_exists swww; then
			if ! pgrep -x swww-daemon >/dev/null 2>&1; then
				swww init >/dev/null 2>&1 &
				disown
				sleep 0.2
			fi
			if [ -f "${wallpaper_path}" ]; then
				if [ "${transitions}" = "1" ]; then
					swww img --transition-type wipe --transition-fps 60 "${wallpaper_path}" >/dev/null 2>&1 &
				else
					swww img "${wallpaper_path}" >/dev/null 2>&1 &
				fi
				disown
			else
				rc_notify "normal" "River" "Wallpaper file not found: ${wallpaper_path}" "1"
			fi
		elif rc_command_exists swaybg; then
			rc_spawn_once "swaybg" swaybg -m fill -i "${wallpaper_path}"
		fi
	else
		rc_kill_if_running "swww-daemon"
		rc_kill_if_running "swaybg"
	fi
}

rc_apply_style() {
	local style
	style="$(state_get style_profile nord)"
	local theme_dir="${CONFIG_DIR}/themes/${style}"
	if [ ! -d "${theme_dir}" ]; then
		rc_notify "normal" "River" "Theme '${style}' not found." "1"
		return
	fi

	# Waybar style
	if [ -f "${theme_dir}/waybar.css" ]; then
		mkdir -p "${HOME}/.config/waybar"
		cp -f "${theme_dir}/waybar.css" "${HOME}/.config/waybar/style.css"
	fi

	# Mako config
	if [ -f "${theme_dir}/mako.conf" ]; then
		mkdir -p "${HOME}/.config/mako"
		cp -f "${theme_dir}/mako.conf" "${HOME}/.config/mako/config"
	fi

	# Fuzzel configuration
	if [ -f "${theme_dir}/fuzzel.ini" ]; then
		mkdir -p "${HOME}/.config/fuzzel"
		cp -f "${theme_dir}/fuzzel.ini" "${HOME}/.config/fuzzel/fuzzel.ini"
	fi

	# Wofi stylesheet
	if [ -f "${theme_dir}/wofi.css" ]; then
		mkdir -p "${HOME}/.config/wofi"
		cp -f "${theme_dir}/wofi.css" "${HOME}/.config/wofi/style.css"
	fi

	# Tofi theme
	if [ -f "${theme_dir}/tofi.toml" ]; then
		mkdir -p "${HOME}/.config/tofi"
		cp -f "${theme_dir}/tofi.toml" "${HOME}/.config/tofi/config"
	fi

	# bemenu styling script
	if [ -f "${theme_dir}/bemenu.sh" ]; then
		mkdir -p "${HOME}/.config/bemenu"
		cp -f "${theme_dir}/bemenu.sh" "${HOME}/.config/bemenu/style.sh"
	fi

	# River border color
	if [ -f "${theme_dir}/river-colors.sh" ]; then
		# shellcheck disable=SC1090
		source "${theme_dir}/river-colors.sh"
		if [ -n "${RIVER_BORDER_COLOR-}" ]; then
			local color="${RIVER_BORDER_COLOR}"
			color="${color#\#}"
			if [[ "${color}" != 0x* ]]; then
				color="0x${color}"
			fi
			riverctl border-color-focused "${color}"
		fi
	fi
}

rc_apply_font_profile() {
	local profile
	profile="$(state_get font_profile sans)"
	case "${profile}" in
	sans)
		export RIVER_FONT_FAMILY="Inter"
		export RIVER_FONT_SIZE="12"
		;;
	mono)
		export RIVER_FONT_FAMILY="JetBrainsMono Nerd Font Mono"
		export RIVER_FONT_SIZE="12"
		;;
	large)
		export RIVER_FONT_FAMILY="Inter"
		export RIVER_FONT_SIZE="14"
		;;
	*)
		export RIVER_FONT_FAMILY="Inter"
		export RIVER_FONT_SIZE="12"
		;;
	esac
}

rc_apply_privacy_mode() {
	local mode
	mode="$(state_get privacy_mode 0)"
	if rc_command_exists pactl; then
		if [ "${mode}" = "1" ]; then
			pactl set-source-mute @DEFAULT_SOURCE@ 1 >/dev/null 2>&1 || true
		else
			pactl set-source-mute @DEFAULT_SOURCE@ 0 >/dev/null 2>&1 || true
		fi
	fi
	if rc_command_exists pw-cli; then
		if [ "${mode}" = "1" ]; then
			pw-cli -ea "update-node-props all media.class=Camera null" >/dev/null 2>&1 || true
		else
			pw-cli -ea "update-node-props all media.class=Camera" >/dev/null 2>&1 || true
		fi
	fi
}

rc_apply_widget_system() {
	local widget
	widget="$(state_get widget_system eww)"
	for candidate in eww ags ; do
		rc_kill_if_running "${candidate}"
	done

	case "${widget}" in
	eww)
		if rc_command_exists eww; then
			rc_spawn_once "eww" eww daemon
		fi
		;;
	ags)
		if rc_command_exists ags; then
			rc_spawn_once "ags" ags
		fi
		;;
	none)
		;;
	esac
}

rc_apply_lock_tool() {
	local tool
	tool="$(state_get lock_tool swaylock)"
	state_set lock_tool "${tool}"
}

rc_apply_zen_mode() {
	local zen
	zen="$(state_get zen_mode 0)"
	if [ "${zen}" = "1" ]; then
		state_set zen_prev_panel "$(state_get panel waybar)"
		state_set zen_prev_wallpaper "$(state_get wallpaper_enabled 1)"
		state_set zen_prev_notifications "$(state_get notifications_enabled 1)"
		state_set panel "none"
		state_set wallpaper_enabled "0"
		state_set notifications_enabled "0"
		rc_apply_panel
		rc_apply_wallpaper
		rc_apply_notifications
	else
		local prev_panel prev_wallpaper prev_notifications
		prev_panel="$(state_get zen_prev_panel waybar)"
		prev_wallpaper="$(state_get zen_prev_wallpaper 1)"
		prev_notifications="$(state_get zen_prev_notifications 1)"
		state_set panel "${prev_panel}"
		state_set wallpaper_enabled "${prev_wallpaper}"
		state_set notifications_enabled "${prev_notifications}"
		rc_apply_panel
		rc_apply_wallpaper
		rc_apply_notifications
	fi
}

rc_current_launcher() {
	state_get launcher fuzzel
}

rc_current_terminal() {
	state_get terminal foot
}

rc_run_launcher() {
	local launcher
	launcher="$(rc_current_launcher)"
	case "${launcher}" in
	fuzzel)
		if rc_command_exists fuzzel; then
			fuzzel &
			disown
		else
			rc_notify "normal" "River" "Launcher 'fuzzel' is not installed." "1"
		fi
		;;
	wofi)
		if rc_command_exists wofi; then
			wofi --show drun &
			disown
		else
			rc_notify "normal" "River" "Launcher 'wofi' is not installed." "1"
		fi
		;;
	tofi)
		if rc_command_exists tofi; then
			tofi --drun &
			disown
		else
			rc_notify "normal" "River" "Launcher 'tofi' is not installed." "1"
		fi
		;;
	bemenu-run)
		if rc_command_exists bemenu-run; then
			local env_file="${HOME}/.config/bemenu/style.sh"
			local BEMENU_ARGS=()
			if [ -f "${env_file}" ]; then
				# shellcheck disable=SC1090
				source "${env_file}"
			fi
			if [ "${#BEMENU_ARGS[@]}" -gt 0 ]; then
				bemenu-run "${BEMENU_ARGS[@]}" &
			else
				bemenu-run &
			fi
			disown
		else
			rc_notify "normal" "River" "Launcher 'bemenu-run' is not installed." "1"
		fi
		;;
	*)
		if rc_command_exists "${launcher}"; then
			"${launcher}" &
			disown
		else
			rc_notify "normal" "River" "Unknown launcher '${launcher}'." "1"
		fi
		;;
	esac
}

rc_run_terminal() {
	local terminal
	terminal="$(rc_current_terminal)"
	case "${terminal}" in
	foot)
		if rc_command_exists foot; then
			foot &
			disown || true
		else
			rc_notify "normal" "River" "Terminal 'foot' is not installed." "1"
		fi
		;;
	kitty)
		if rc_command_exists kitty; then
			kitty &
			disown || true
		else
			rc_notify "normal" "River" "Terminal 'kitty' is not installed." "1"
		fi
		;;
	alacritty)
		if rc_command_exists alacritty; then
			alacritty &
			disown || true
		else
			rc_notify "normal" "River" "Terminal 'alacritty' is not installed." "1"
		fi
		;;
	wezterm)
		if rc_command_exists wezterm; then
			wezterm &
			disown || true
		else
			rc_notify "normal" "River" "Terminal 'wezterm' is not installed." "1"
		fi
		;;
	gnome-terminal)
		if rc_command_exists gnome-terminal; then
			gnome-terminal &
			disown || true
		else
			rc_notify "normal" "River" "Terminal 'gnome-terminal' is not installed." "1"
		fi
		;;
	*)
		if rc_command_exists "${terminal}"; then
			"${terminal}" &
			disown || true
		else
			rc_notify "normal" "River" "Unknown terminal '${terminal}'." "1"
		fi
		;;
	esac
}

rc_lock_screen() {
	local lock_tool
	lock_tool="$(state_get lock_tool swaylock)"
	case "${lock_tool}" in
	swaylock)
		if rc_command_exists swaylock; then
			swaylock -f
		else
			rc_notify "critical" "River" "swaylock not available." "1"
		fi
		;;
	swaylock-effects)
		if rc_command_exists swaylock; then
			swaylock --effect-blur 7x5 --effect-vignette 0.5:0.5 -f
		else
			rc_notify "critical" "River" "swaylock-effects not available." "1"
		fi
		;;
	gtklock)
		if rc_command_exists gtklock; then
			gtklock
		else
			rc_notify "critical" "River" "gtklock not available." "1"
		fi
		;;
	waylock)
		if rc_command_exists waylock; then
			waylock
		else
			rc_notify "critical" "River" "waylock not available." "1"
		fi
		;;
	esac
}

rc_reload_river() {
	riverctl spawn "riverctl restart"
}

rc_workspace_switch() {
	local target="$1"
	riverctl set-focused-tags "$target"
}

rc_workspace_move_view() {
	local target="$1"
	riverctl set-view-tags "$target"
}

rc_toggle_focused_fullscreen() {
	riverctl toggle-fullscreen
}

rc_toggle_floating() {
	riverctl toggle-float
}

rc_notify_bindings() {
	local notification
	read -r -d '' notification <<'EOF' || true
Super+Space → Run launcher
Super+Enter / Super+E → Run terminal
Super+T → Toggle layer (Space launcher, N notifications, E terminal, F font, S style, W wallpaper, B panel, L locker, G widgets, R recorder)
Super+D → Debug mode toggle (press Space/N/E/F/S/W/B/L/G/R in debug mode to reset defaults)
Super+H → Show this help
Super+P → Privacy mode
Super+Shift+Z → Zen mode
Super+Shift+R → Reload River
Super+L → Lock screen
Print / Shift+Print / Alt+Print → Screenshots
Ctrl+Print → Screen record toggle
Fn+Arrows → Brightness/Volume
Super+O → Toggle workspace layout
Super+Tab / Shift+Tab → Cycle workspaces
Super+Alt → Previous workspace
Super+F → Toggle floating
Super+Shift+F → Toggle fullscreen
EOF
	rc_notify "normal" "River Keybinds" "${notification}" "1"
}

rc_launch_daemon() {
	local label="$1"
	shift
	local pid_file="${RUNTIME_DIR}/${label}.pid"
	if [ -f "${pid_file}" ]; then
		local existing_pid
		existing_pid=$(cat "${pid_file}")
		if kill -0 "${existing_pid}" >/dev/null 2>&1; then
			return 0
		fi
	fi
	("$@") &
	local pid=$!
	disown "${pid}" 2>/dev/null || true
	printf '%s\n' "${pid}" >"${pid_file}"
}

rc_stop_daemon() {
	local label="$1"
	local pid_file="${RUNTIME_DIR}/${label}.pid"
	if [ -f "${pid_file}" ]; then
		local pid
		pid=$(cat "${pid_file}")
		if kill -0 "${pid}" >/dev/null 2>&1; then
			kill "${pid}" >/dev/null 2>&1 || true
		fi
		rm -f "${pid_file}"
	fi
}

rc_force_dark_theme() {
	if [ -f "${BIN_DIR}/apply-dark-theme.sh" ]; then
		"${BIN_DIR}/apply-dark-theme.sh" >/dev/null 2>&1 &
		disown
	fi
}

rc_start_helpers() {
	if [ -f "${BIN_DIR}/battery-monitor.sh" ]; then
		rc_launch_daemon "battery-monitor" "${BIN_DIR}/battery-monitor.sh"
	fi
	if [ -f "${BIN_DIR}/clipboard-scrubber.sh" ]; then
		rc_launch_daemon "clipboard-scrubber" "${BIN_DIR}/clipboard-scrubber.sh"
	fi
	if [ -f "${BIN_DIR}/workspace-tracker.sh" ]; then
		rc_launch_daemon "workspace-tracker" "${BIN_DIR}/workspace-tracker.sh"
	fi
	if [ -f "${BIN_DIR}/idle-handler.sh" ]; then
		rc_launch_daemon "idle-handler" "${BIN_DIR}/idle-handler.sh"
	fi
	if [ -f "${BIN_DIR}/theme-sync-dark.sh" ]; then
		rc_launch_daemon "theme-sync" "${BIN_DIR}/theme-sync-dark.sh"
	fi
}

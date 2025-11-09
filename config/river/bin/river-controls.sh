#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="${HOME}/.config/river"
BIN_DIR="${CONFIG_DIR}/bin"

# shellcheck disable=SC1091
source "${BIN_DIR}/river-lib.sh"

ensure_state

command="${1:-}"
shift || true
rc_log_action() {
	if [ "$(state_get debug_mode 0)" != "1" ]; then
		return
	fi
	local log_file="${RUNTIME_DIR}/river-controls.log"
	mkdir -p "${RUNTIME_DIR}"
	printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"${log_file}"
}
rc_log_action "command=${command} args=$*"

workspace_index() {
	local index="$1"
	if [ "${index}" = "0" ]; then
		index=10
	fi
	printf '%s\n' "${index}"
}

workspace_mask() {
	local idx
	idx="$(workspace_index "$1")"
	echo $((1 << (idx - 1)))
}

toggle_value() {
	local key="$1"
	local current
	current="$(state_get "${key}" 0)"
	if [ "${current}" = "1" ]; then
		state_set "${key}" "0"
		printf '0\n'
	else
		state_set "${key}" "1"
		printf '1\n'
	fi
}

case "${command}" in
launcher)
	sub="${1:-}"
	case "${sub}" in
	run)
		rc_run_launcher
		rc_debug_note "Launcher $(rc_current_launcher) invoked."
		;;
	cycle)
		new_launcher="$(cycle_value launcher "${LAUNCHER_OPTIONS[@]}")"
		rc_notify "normal" "Launcher" "Launcher set to: ${new_launcher}" "0"
		;;
	reset)
		state_set launcher "${DEFAULTS[launcher]}"
		rc_notify "normal" "Launcher" "Launcher reset to ${DEFAULTS[launcher]}." "0"
		;;
	esac
	;;
terminal)
	sub="${1:-}"
	case "${sub}" in
	run)
		rc_run_terminal
		rc_debug_note "Terminal $(rc_current_terminal) invoked."
		;;
	cycle)
		new_terminal="$(cycle_value terminal "${TERMINAL_OPTIONS[@]}")"
		rc_notify "normal" "Terminal" "Terminal set to: ${new_terminal}" "0"
		;;
	reset)
		state_set terminal "${DEFAULTS[terminal]}"
		rc_notify "normal" "Terminal" "Terminal reset to ${DEFAULTS[terminal]}." "0"
		;;
	esac
	;;
notifications)
	sub="${1:-}"
	case "${sub}" in
	toggle-manager)
		current="$(state_get notification_manager mako)"
		if [ "${current}" = "mako" ]; then
			rc_notify "normal" "Notifications" "Disabling mako in 3 seconds..." "1"
			sleep 3
			state_set notification_manager "none"
			state_set notifications_enabled "0"
			rc_apply_notifications
		else
			state_set notification_manager "mako"
			state_set notifications_enabled "1"
			rc_apply_notifications
			sleep 1
			rc_notify "normal" "Notifications" "Notification manager set to mako." "1"
		fi
		;;
	toggle-enabled)
		value="$(toggle_value notifications_enabled)"
		rc_apply_notifications
		if [ "${value}" = "1" ]; then
			rc_notify "normal" "Notifications" "Notifications enabled." "1"
		else
			rc_notify "normal" "Notifications" "Notifications disabled." "1"
		fi
		;;
	reset)
		state_set notification_manager "${DEFAULTS[notification_manager]}"
		state_set notifications_enabled "${DEFAULTS[notifications_enabled]}"
		rc_apply_notifications
		rc_notify "normal" "Notifications" "Notifications reset to defaults." "0"
		;;
	esac
	;;
debug)
	sub="${1:-toggle}"
	case "${sub}" in
	toggle)
		value="$(toggle_value debug_mode)"
		if [ "${value}" = "1" ]; then
			rc_notify "normal" "Debug Mode" "Debug notifications enabled." "1"
		else
			rc_notify "normal" "Debug Mode" "Debug notifications disabled." "1"
		fi
		;;
	reset)
		state_set debug_mode "${DEFAULTS[debug_mode]}"
		rc_notify "normal" "Debug Mode" "Debug mode reset." "0"
		;;
	esac
	;;
font)
	sub="${1:-}"
	case "${sub}" in
	cycle)
		new_font="$(cycle_value font_profile "${FONT_OPTIONS[@]}")"
		rc_apply_font_profile
		rc_notify "normal" "Font Profile" "Font profile: ${new_font}" "0"
		;;
	reset)
		state_set font_profile "${DEFAULTS[font_profile]}"
		rc_apply_font_profile
		rc_notify "normal" "Font Profile" "Font profile reset." "0"
		;;
	esac
	;;
style)
	sub="${1:-}"
	case "${sub}" in
	cycle)
		new_style="$(cycle_value style_profile "${STYLE_OPTIONS[@]}")"
		rc_apply_style
		rc_notify "normal" "Style" "Style set to: ${new_style}" "0"
		;;
	reset)
		state_set style_profile "${DEFAULTS[style_profile]}"
		rc_apply_style
		rc_notify "normal" "Style" "Style reset." "0"
		;;
	esac
	;;
wallpaper)
	sub="${1:-}"
	case "${sub}" in
	toggle)
		value="$(toggle_value wallpaper_enabled)"
		rc_apply_wallpaper
		if [ "${value}" = "1" ]; then
			rc_notify "normal" "Wallpaper" "Animated wallpaper enabled." "0"
		else
			rc_notify "normal" "Wallpaper" "Wallpaper disabled." "0"
		fi
		;;
	transitions)
		value="$(toggle_value wallpaper_transitions)"
		if [ "${value}" = "1" ]; then
			rc_notify "normal" "Wallpaper" "Transitions enabled." "0"
		else
			rc_notify "normal" "Wallpaper" "Transitions disabled." "0"
		fi
		;;
	reset)
		state_set wallpaper_enabled "${DEFAULTS[wallpaper_enabled]}"
		state_set wallpaper_transitions "${DEFAULTS[wallpaper_transitions]}"
		rc_apply_wallpaper
		rc_notify "normal" "Wallpaper" "Wallpaper settings reset." "0"
		;;
	esac
	;;
panel)
	sub="${1:-}"
	case "${sub}" in
	cycle)
		new_panel="$(cycle_value panel "${PANEL_OPTIONS[@]}")"
		rc_apply_panel
		rc_notify "normal" "Panel" "Panel set to: ${new_panel}" "0"
		;;
	reset)
		state_set panel "${DEFAULTS[panel]}"
		rc_apply_panel
		rc_notify "normal" "Panel" "Panel reset." "0"
		;;
	open-audio)
		if rc_command_exists pavucontrol; then
			pavucontrol &
			disown
		elif rc_command_exists helvum; then
			helvum &
			disown
		else
			rc_notify "normal" "Panel" "Install pavucontrol or helvum." "1"
		fi
		;;
	open-power)
		if rc_command_exists gnome-control-center; then
			gnome-control-center power &
			disown
		elif rc_command_exists wdisplays; then
			wdisplays &
			disown
		else
			rc_notify "normal" "Panel" "Install gnome-control-center or wdisplays." "1"
		fi
		;;
	open-monitor)
		if rc_command_exists btop; then
			foot -e btop &
			disown
		else
			rc_notify "normal" "System Monitor" "Install btop for monitoring." "1"
		fi
		;;
	esac
	;;
widget)
	sub="${1:-}"
	case "${sub}" in
	cycle)
		new_widget="$(cycle_value widget_system "${WIDGET_SYSTEMS[@]}")"
		rc_apply_widget_system
		rc_notify "normal" "Widgets" "Widget system set to: ${new_widget}" "0"
		;;
	reset)
		state_set widget_system "${DEFAULTS[widget_system]}"
		rc_apply_widget_system
		rc_notify "normal" "Widgets" "Widget system reset." "0"
		;;
	esac
	;;
lock)
	sub="${1:-immediate}"
	case "${sub}" in
	immediate)
		rc_lock_screen
		;;
	cycle)
		new_lock="$(cycle_value lock_tool "${LOCKER_OPTIONS[@]}")"
		rc_notify "normal" "Screen Lock" "Lock tool set to: ${new_lock}" "0"
		;;
	reset)
		state_set lock_tool "${DEFAULTS[lock_tool]}"
		rc_notify "normal" "Screen Lock" "Lock tool reset." "0"
		;;
	esac
	;;
display)
	sub="${1:-}"
	case "${sub}" in
	off)
		if rc_command_exists wlopm; then
			wlopm --off '*'
		elif rc_command_exists swaymsg; then
			swaymsg 'output * dpms off' >/dev/null 2>&1 || true
		fi
		;;
	on)
		if rc_command_exists wlopm; then
			wlopm --on '*'
		elif rc_command_exists swaymsg; then
			swaymsg 'output * dpms on' >/dev/null 2>&1 || true
		fi
		;;
	esac
	;;
	workspace)
		sub="${1:-}"
		case "${sub}" in
		switch)
			target="${2:-1}"
			index="$(workspace_index "${target}")"
			current="$(workspace_index "$(state_get current_workspace 1)")"
			if [ "${index}" != "${current}" ]; then
				state_set last_workspace "${current}"
			fi
			state_set current_workspace "${index}"
			riverctl set-focused-tags "$(workspace_mask "${index}")"
			;;
		move)
			target="${2:-1}"
			riverctl set-view-tags "$(workspace_mask "${target}")"
			;;
		next)
			current="$(workspace_index "$(state_get current_workspace 1)")"
			next=$((current + 1))
			if [ "${next}" -gt 10 ]; then
				next=1
			fi
			state_set last_workspace "${current}"
			state_set current_workspace "${next}"
			riverctl set-focused-tags "$(workspace_mask "${next}")"
			;;
		prev)
			current="$(workspace_index "$(state_get current_workspace 1)")"
			prev=$((current - 1))
			if [ "${prev}" -lt 1 ]; then
				prev=10
			fi
			state_set last_workspace "${current}"
			state_set current_workspace "${prev}"
			riverctl set-focused-tags "$(workspace_mask "${prev}")"
			;;
		last)
			last="$(workspace_index "$(state_get last_workspace 1)")"
			current="$(workspace_index "$(state_get current_workspace 1)")"
			state_set current_workspace "${last}"
			state_set last_workspace "${current}"
			riverctl set-focused-tags "$(workspace_mask "${last}")"
			;;
		layout-toggle)
			mode="$(state_get workspace_mode tiling)"
			if [ "${mode}" = "tiling" ]; then
				state_set workspace_mode "stacking"
				riverctl send-layout-cmd rivertile "main-count 0"
				rc_notify "normal" "Workspace" "Stacking layout enabled." "0"
			else
				state_set workspace_mode "tiling"
				riverctl send-layout-cmd rivertile "main-count 1"
				rc_notify "normal" "Workspace" "Tiling layout enabled." "0"
			fi
			;;
		esac
		;;
reload)
	rc_reload_river
	;;
brightness)
	direction="${1:-up}"
	step="${2:-5%}"
	if ! rc_command_exists brightnessctl; then
		rc_notify "normal" "Brightness" "Install brightnessctl for brightness control." "1"
		exit 1
	fi
	if [ "${direction}" = "up" ]; then
		brightnessctl set "+${step}" >/dev/null 2>&1
	else
		brightnessctl set "${step}-" >/dev/null 2>&1
	fi
	level="$(brightnessctl get)"
	if rc_command_exists swayosd-client; then
		swayosd-client --brightness "${level}" >/dev/null 2>&1 || true
	else
		rc_notify "low" "Brightness" "Brightness level: ${level}" "0"
	fi
	;;
volume)
	direction="${1:-up}"
	if rc_command_exists pamixer; then
		case "${direction}" in
		up)
			pamixer --increase 5
			;;
		down)
			pamixer --decrease 5
			;;
		mute)
			pamixer --toggle-mute
			;;
		esac
		volume="$(pamixer --get-volume)"
		muted="$(pamixer --get-mute && echo muted)"
	else
		case "${direction}" in
		up)
			pactl set-sink-volume @DEFAULT_SINK@ +5%
			;;
		down)
			pactl set-sink-volume @DEFAULT_SINK@ -5%
			;;
		mute)
			pactl set-sink-mute @DEFAULT_SINK@ toggle
			;;
		esac
		volume="$(pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1{print $5}')"
		muted="$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')"
	fi
	if rc_command_exists swayosd-client; then
		swayosd-client --volume "${volume}" >/dev/null 2>&1 || true
	else
		rc_notify "low" "Volume" "Volume: ${volume} ${muted}" "0"
	fi
	;;
defaults)
	target="${1:-}"
	case "${target}" in
	launcher)
		state_set launcher "${DEFAULTS[launcher]}"
		rc_notify "normal" "Defaults" "Launcher reset to default." "0"
		;;
	terminal)
		state_set terminal "${DEFAULTS[terminal]}"
		rc_notify "normal" "Defaults" "Terminal reset to default." "0"
		;;
	notifications)
		state_set notification_manager "${DEFAULTS[notification_manager]}"
		state_set notifications_enabled "${DEFAULTS[notifications_enabled]}"
		rc_apply_notifications
		rc_notify "normal" "Defaults" "Notifications reset to default." "0"
		;;
	font)
		state_set font_profile "${DEFAULTS[font_profile]}"
		rc_apply_font_profile
		rc_notify "normal" "Defaults" "Font profile reset." "0"
		;;
	style)
		state_set style_profile "${DEFAULTS[style_profile]}"
		rc_apply_style
		rc_notify "normal" "Defaults" "Style reset." "0"
		;;
	wallpaper)
		state_set wallpaper_enabled "${DEFAULTS[wallpaper_enabled]}"
		state_set wallpaper_transitions "${DEFAULTS[wallpaper_transitions]}"
		rc_apply_wallpaper
		rc_notify "normal" "Defaults" "Wallpaper reset." "0"
		;;
	panel)
		state_set panel "${DEFAULTS[panel]}"
		rc_apply_panel
		rc_notify "normal" "Defaults" "Panel reset." "0"
		;;
	widget)
		state_set widget_system "${DEFAULTS[widget_system]}"
		rc_apply_widget_system
		rc_notify "normal" "Defaults" "Widget system reset." "0"
		;;
	lock)
		state_set lock_tool "${DEFAULTS[lock_tool]}"
		rc_apply_lock_tool
		rc_notify "normal" "Defaults" "Lock tool reset." "0"
		;;
	esac
	;;
privacy)
	value="$(toggle_value privacy_mode)"
	rc_apply_privacy_mode
	if [ "${value}" = "1" ]; then
		rc_notify "normal" "Privacy" "Privacy mode ON" "1"
	else
		rc_notify "normal" "Privacy" "Privacy mode OFF" "1"
	fi
	;;
zen)
	value="$(toggle_value zen_mode)"
	rc_apply_zen_mode
	if [ "${value}" = "1" ]; then
		rc_notify "normal" "Zen Mode" "Zen mode enabled." "1"
	else
		rc_notify "normal" "Zen Mode" "Zen mode disabled." "1"
	fi
	;;
screenshot)
	mode="${1:-full}"
	if [ -f "${BIN_DIR}/screenshot.sh" ]; then
		"${BIN_DIR}/screenshot.sh" "${mode}"
	fi
	;;
record)
	mode="${1:-toggle}"
	scope="${2:-full}"
	if [ -f "${BIN_DIR}/screen-record.sh" ]; then
		"${BIN_DIR}/screen-record.sh" "${mode}" "${scope}"
	fi
	;;
clipboard)
	action="${1:-clear}"
	if [ "${action}" = "clear" ]; then
		if rc_command_exists wl-copy; then
			wl-copy --clear
			rc_notify "normal" "Clipboard" "Clipboard cleared." "0"
		fi
	fi
	;;
help)
	rc_notify_bindings
	;;
*)
	echo "Unknown control command: ${command}" >&2
	exit 1
	;;
esac

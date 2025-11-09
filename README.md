# River Desktop Setup for Arch Linux

This repository delivers a full River compositor experience tailored for Arch Linux (and derivatives). It includes:

- Modular configuration with launcher/terminal/theme toggles, per-style accenting, notification controls, wallpaper automation, and debug/default modes.
- Helper daemons for battery alerts, clipboard scrubbing, privacy toggles, idle locking, and dark-theme synchronisation.
- Installation scripts that pull in Wayland prerequisites (portals, PipeWire/WirePlumber, seatd) and copy the configuration tree into `~/.config/river/`.

## Requirements

- Arch Linux or derivative with Wayland-capable GPU (proprietary NVIDIA requires extra tuning).
- Ability to run `sudo` for `pacman` installs.
- A login manager or TTY that can start Wayland sessions.
- Optional AUR helper (`paru`/`yay`) for `ags`/`eww`.

**Key runtime dependencies** (installed by `scripts/install-packages.sh`):

- River ecosystem: `river`, `rivertile`, `seatd`.
- Portals & PipeWire stack: `xdg-desktop-portal`, `xdg-desktop-portal-wlr`, `xdg-desktop-portal-gtk`, `pipewire`, `wireplumber`.
- Interface extras: `waybar`, `yambar`, `nwg-panel`, `mako`, `swww`, `swaybg`, `swayosd`, `wlopm`, `swayidle`, `swaylock`, `swaylock-effects`, `gtklock`, `waylock`.
- Launchers & terminals: `fuzzel`, `wofi`, `tofi`, `bemenu`, `foot`, `kitty`, `alacritty`, `wezterm`.
- Tooling: `brightnessctl`, `pamixer`, `wl-clipboard`, `grim`, `slurp`, `wf-recorder`, `helvum`, `pavucontrol`, `btop`, `upower`, `kvantum`, `qt5ct`, `qt6ct`, `libnotify`, `xdg-user-dirs`.
- Optional widgets: `eww`, `ags` (installed when an AUR helper is available).

## Installation

1. Clone the repository and enter it.
2. Install prerequisites (installs pacman packages and optional AUR widgets):

   ```bash
   ./scripts/install-packages.sh
   ```

3. Deploy the River configuration (backups any existing setup to `~/.config/river.YYYYMMDDHHMMSS.bak`):

   ```bash
   ./scripts/install-config.sh
   ```

   Alternatively, run everything in one shot with `./scripts/install.sh`.

4. Log into a Wayland session and start River (via display manager entry or by running `river` from a TTY).

Configuration state is kept independent of the repository in `~/.config/river/state/settings.env`, so edits to the live setup won't overwrite your tracked files.

## Repository Layout

- `config/river/init` – Main River init script (bash) wiring modes, mappings, helpers, and service start-up.
- `config/river/bin/river-lib.sh` – Shared helper library (state management, notifications, service wrappers, theme logic).
- `config/river/bin/river-controls.sh` – CLI entry point invoked by keybinds (`launcher`, `terminal`, `workspace`, `wallpaper`, `panel`, `widget`, `privacy`, `zen`, `record`, etc.).
- `config/river/bin/*.sh` – Utility scripts (idle handler, screenshots/recording, theme sync, battery monitor, clipboard scrubber, toggle/default wrappers).
- `config/river/themes/{nord,gruvbox,mocha}` – Theme collections with Waybar CSS, Mako configs, and River border colors; switching styles copies the relevant assets.
- `scripts/install-packages.sh` / `scripts/install-config.sh` – Setup helpers described above.

## Keybind Cheat Sheet

| Keys | Action | Notes |
| --- | --- | --- |
| `Super + Space` | Launch current application launcher | Uses `fuzzel`, `wofi`, `tofi`, or `bemenu-run` (toggle below). |
| `Super + Enter` / `Super + E` | Launch current terminal | Cycles through `foot`, `kitty`, `alacritty`, `wezterm`, `gnome-terminal`. |
| `Super + T` then `Space / N / E / F / S / W / Shift+W / B / L / G / R / A / P / M` | Toggle launcher, notifications, terminal, font profile, style, wallpaper, wallpaper transitions, panel, lock tool, widget system, screen recorder mode, audio panel, power panel, or monitoring terminal | Uses `toggle-command.sh` to execute and auto-exit toggle mode. |
| `Super + D` (tap) | Toggle debug notifications | Debug forces notifications for all actions. |
| `Super + D` then `Space / E / N / F / S / W / B / G / L` | Reset launcher/terminal/notifications/font/style/wallpaper/panel/widget/lock to defaults | Defaults defined in `river-lib.sh`. |
| `Super + H` | Show hotkey list via notification | Always forced. |
| `Super + P` | Toggle privacy mode | Mutes default microphone and attempts to suspend camera streams. |
| `Super + Shift + Z` | Toggle Zen mode | Hides wallpaper, panel, and notifications (restores on exit). |
| `Super + Q` / `Super + Shift + Q` | Close focused view / exit River | No notifications. |
| `Super + L` | Immediate lock using selected locker | Cycle locker under `Super + T + L`. |
| `Super + O` | Toggle current workspace layout between tiling and stacking | Switches rivertile `main-count` between 1 and 0. |
| `Super + F` | Toggle floating for focused view | Silent unless debug enabled. |
| `Super + Shift + F` | Toggle fullscreen for focused view | Silent unless debug enabled. |
| `Super + ←/→/↑/↓` | Change focus | Works in tiling/floating. |
| `Super + Shift + ←/→` | Move the focused tile left/right | Rivertile swap commands in tiling mode. |
| `Super + Shift + ↑/↓` | Re-stack the focused tile above/below | Rivertile main/stack rotation in tiling mode. |
| `Super + 1…0` | Switch to workspace 1–10 | Maintains last workspace history. |
| `Super + Shift + 1…0` | Move focused window to workspace | |
| `Super + Tab` / `Super + Shift + Tab` | Next / previous workspace | |
| `Super + Alt + Backspace` | Jump to last workspace | River cannot bind pure modifiers, so Backspace is used as the trigger key. |
| `Super + Shift + R` | Reload River compositor | Calls `riverctl restart`. |
| `Super + T + R` | Toggle area screen recording | Uses `wf-recorder`, saved under `~/Videos/Recordings/`. |
| `Super + T + W` | Toggle animated wallpaper handling | Uses `swww`; transitions toggled with `Shift + W`. |
| `Super + T + B` | Cycle panel between Waybar, Yambar, nwg-panel, off | |
| `Super + T + G` | Cycle widget systems (`eww`, `ags`, none) | Starts daemon if available. |
| `Super + T + A / P / M` | Launch audio mixer (`pavucontrol`/`helvum`), power panel (`gnome-control-center`), or system monitor (`btop`) | |
| `Super + T + F/S` | Cycle font or style themes | Style swaps Waybar/Mako assets and River border colors. |
| `Super + T + Space / E` | Cycle launcher / terminal preference | Sends notification with new selection. |
| `Print / Shift+Print / Alt+Print` | Full / area / window screenshot | Saved to `~/Pictures/Screenshots/` and copied to clipboard. |
| `Ctrl + Print` | Toggle full-screen recording | Uses `wf-recorder`, toggles stop/start. |
| `Super + Shift + C` | Clear clipboard immediately | Clipboard also auto-clears after timeout. |
| `XF86Audio*` or `Fn + Up/Down` | Volume up/down/mute | Uses `pamixer`/`pactl` with `swayosd` feedback where available. |
| `XF86MonBrightness*` or `Fn + Left/Right` | Adjust display brightness | Uses `brightnessctl` + `swayosd`. |

Debug mode ensures every command emits a notification, even if the base binding is silent.

## Background Services & Automations

The init script launches several helpers located under `config/river/bin/`:

- `battery-monitor.sh` – Polls `/sys/class/power_supply/*` every minute, warns and dims brightness when below `battery_threshold` (default `20`%).
- `clipboard-scrubber.sh` – Clears the Wayland clipboard after `clipboard_timeout_minutes` (default `15`) if unchanged, with opt-out via state edits.
- `idle-handler.sh` – Runs `swayidle` to lock after 10 minutes of inactivity, powers down displays via `wlopm`, and resumes on input.
- `apply-dark-theme.sh` – Forces dark variants for GTK, Qt, Kvantum, and GNOME settings.
- `screen-record.sh` / `screenshot.sh` – Used by keybinds; recordings land under `~/Videos/Recordings/`.
- `river-controls.sh` – Accepts subcommands for toggles, resets, workspace tracking, privacy, zen, brightness/volume, screenshotting, and more.
- `river-lib.sh` – Stores defaults, handles notifications (preferring Mako), theme application, service launching, and state persistence.

State (including selected launcher/terminal/panel/style, debug flag, privacy & zen state) is persisted in `~/.config/river/state/settings.env`. Defaults reside in `river-lib.sh` near the top for quick editing.

## Themes, Styles, and Accents

Theme switching copies assets from `config/river/themes/<style>/` into user config locations:

- `themes/*/waybar.css` → `~/.config/waybar/style.css`
- `themes/*/mako.conf` → `~/.config/mako/config`
- `themes/*/river-colors.sh` → Sets focused border color via `riverctl`

Add your own style by creating a new folder with the same file set and append the style name to `STYLE_OPTIONS` in `river-lib.sh`.

Font profiles update exported `RIVER_FONT_FAMILY/SIZE` variables that can be consumed by bar/widget configs. Adjust `rc_apply_font_profile` in `river-lib.sh` to suit your stack.

## Privacy, Notifications, and Zen Mode

- **Privacy toggle (`Super + P`)** mutes the default microphone via `pactl`/`pamixer` and attempts to disable camera nodes with `pw-cli`. Extend `rc_apply_privacy_mode` for more aggressive actions if desired.
- **Notification toggle (`Super + T + N`)** switches between Mako and “off”. Turning notifications off sends a final warning before stopping the daemon; re-enabling restarts Makó and notifies you.
- **Zen mode (`Super + Shift + Z`)** stashes current panel/wallpaper/notification settings, disables them, and restores everything on exit.

## Wallpaper & Animation

- Wallpaper support defaults to `swww` with wipe transitions at 60 FPS. `Super + T + W` fully disables/reenables wallpaper handling; `Super + T + Shift + W` toggles the transition effect.
- The active wallpaper path is stored in state (`wallpaper_path`). Update it via `state_set` or by editing `settings.env`. Fallback to `swaybg` occurs if `swww` is missing.

## Debug & Hotkey Safety

- Debug mode (`Super + D` tap) forces every action to emit a notification — handy for spotting what command actually ran.
- Pressing `Super + D` followed by a toggle key (Space/E/N/…) taps into the defaults mode, resetting values to the defaults declared in `river-lib.sh`.
- The init script tracks all bindings and surfaces duplicates at startup through a critical notification, making conflicts obvious.

## Customisation Tips

- Override defaults by editing the `DEFAULTS` associative array in `config/river/bin/river-lib.sh` (launcher list, terminal list, initial theme, battery threshold, clipboard timeout, etc.).
- Add or remove toggle options by editing the respective arrays (`LAUNCHER_OPTIONS`, `TERMINAL_OPTIONS`, `PANEL_OPTIONS`, `STYLE_OPTIONS`, `FONT_OPTIONS`, `LOCKER_OPTIONS`, `WIDGET_SYSTEMS`).
- Adjust idle timeout or DPMS behaviour in `config/river/bin/idle-handler.sh`.
- Extend privacy mode, battery alerts, or widget toggles by patching the relevant helper in `config/river/bin/`.
- To supply additional wallpaper logic, replace `rc_apply_wallpaper` or point `wallpaper_path` at a script that returns your desired image.

## Utilities & Suggestions

- Audio control hotkey launches `pavucontrol`; `helvum` (if installed) is used as fallback.
- Power management key opens `gnome-control-center power`; `wdisplays` acts as an alternative.
- Monitoring key spawns `btop` in a terminal for RAM/CPU/GPU/storage overview (consider integrating the metrics into Waybar modules).
- Screenshot and recorder scripts rely on `grim`, `slurp`, and `wf-recorder`, favouring clipboard delivery for fast sharing.
- Widget toggling expects you to have config for the chosen system (`eww` or `ags`). Disable by cycling to `none`.

## Removal

To remove the configuration while leaving packages installed:

```bash
rm -r ~/.config/river
```

Remove packages with `sudo pacman -Rns <package>` (and `paru -Rns`/`yay -Rns` for AUR helpers where used).

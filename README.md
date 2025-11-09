# River Desktop Setup for Arch Linux

This repository provides a curated River compositor configuration together with an installation helper for Arch Linux systems.

## Contents

- `config/river/init` &mdash; River initialization script with sensible defaults and bindings.
- `scripts/install.sh` &mdash; Installs the required packages and symlinks the configuration into `~/.config/river`.

## Prerequisites

- Arch Linux (or derivative) with access to `sudo`.
- Wayland-compatible environment (use a proper login manager or a TTY).

## Installation

1. Clone this repository somewhere under your user account.
2. Run the installer:

   ```bash
   ./scripts/install.sh
   ```

   The script installs the packages listed inside and links the River config to `~/.config/river/init`. Existing configs are backed up with a timestamped `.bak` suffix.

3. Log in to a Wayland session and start River (for example through your display manager or by running `river` from a TTY).

## Customisation

- Update bindings, applications, or autostart programs by editing `config/river/init`.
- Add user-specific autostart logic by creating an executable `~/.config/river/autostart.sh`. The init script runs it automatically if present.

## Removing

To undo the symlink created by the installer:

```bash
rm ~/.config/river/init
```

Packages can be removed using `sudo pacman -Rns <package>`.

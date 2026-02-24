# remind-me-cli

Simple Bash reminder CLI for Linux with:

- local desktop notifications via `notify-send`
- Discord notifications via webhook
- a lightweight background daemon for queued reminders
- recurring reminders

## Features

- One-time reminders: `10m`, `90s`, `1h30m`
- Absolute-time reminders: `--at "YYYY-MM-DD HH:MM[:SS]"`
- Recurring reminders: `every 30m`
- Queue management: `list`, `remove`, `clear`
- Recurring controls: `pause`, `resume`
- Snooze by ID

## Requirements

- Linux
- Bash
- `date` (GNU coreutils)
- Optional:
  - `notify-send` (desktop notifications)
  - `curl` (Discord webhook notifications)

Install `notify-send` on Debian/Ubuntu:

```bash
sudo apt install libnotify-bin
```

## Quick Start

Make the script executable:

```bash
chmod +x ./remindme
```

Start the daemon once:

```bash
./remindme start
```

Add reminders:

```bash
./remindme 10m Stretch and drink water
./remindme add 90s Check the oven
./remindme --at "2026-02-25 18:30" Join standup
./remindme every 30m Drink water
```

Check queue / daemon:

```bash
./remindme list
./remindme status
```

Stop the daemon:

```bash
./remindme stop
```

`make install` installs both the CLI and the `systemd --user` unit. Then enable the service:

```bash
make install
make systemd-enable
```

## Discord Webhook Setup

Create a webhook in your Discord channel settings.

### Recommended for `systemd --user` (persistent across reboot/login)

Create `~/.config/remindme.env`:

```bash
mkdir -p ~/.config
cat > ~/.config/remindme.env <<'EOF'
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
EOF
chmod 600 ~/.config/remindme.env
```

The included `systemd` unit loads this file automatically via `EnvironmentFile=`.

After creating or changing it:

```bash
systemctl --user daemon-reload
systemctl --user restart remindme.service
```

### Shell export (works for manual use / client shell)

You can also export it in your shell:

```bash
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."
```

This is fine for `./remindme ...` client commands and manual daemon mode, but `systemd --user` should use `~/.config/remindme.env` for reliable startup after reboot/login.

The script captures this env var when you run `start`, `add`, or `every` (manual mode).

If you change the webhook URL later:

- `systemd --user` mode: restart the service
- manual daemon mode: run `./remindme start` again (or any `add/every` command to refresh the snapshot)

## Desktop Notification Notes (`notify-send`)

`notify-send` requires your desktop session environment (`DISPLAY`, DBus session vars).

This script captures the relevant environment variables when you run:

- `./remindme start`
- `./remindme add ...`
- `./remindme every ...`

If desktop notifications stop working after login/session changes, restart the daemon:

```bash
./remindme stop
./remindme start
```

## Commands

Show help:

```bash
./remindme --help
```

Main commands:

```bash
./remindme start
./remindme stop
./remindme status
./remindme list
./remindme add <delay> <message...>
./remindme add --at "YYYY-MM-DD HH:MM[:SS]" <message...>
./remindme every <interval> <message...>
./remindme snooze <id> <delay>
./remindme pause <id>
./remindme resume <id>
./remindme remove <id>
./remindme clear
```

Shortcut forms (same as `add`):

```bash
./remindme 10m Take a break
./remindme --at "2026-02-25 21:00" Shutdown server
```

## Queue Management Examples

List reminders (includes `id=...` values):

```bash
./remindme list
```

Remove one reminder:

```bash
./remindme remove 1771961521-1771961491548797381
```

Snooze one reminder by 10 minutes:

```bash
./remindme snooze 1771961521-1771961491548797381 10m
```

Pause/resume a recurring reminder:

```bash
./remindme pause 1771961521-1771961491544791626
./remindme resume 1771961521-1771961491544791626
```

Clear all queued reminders:

```bash
./remindme clear
```

## Install (CLI + systemd unit)

Default install with `make`:

```bash
make install
```

This does both:

- installs `remindme` to `/usr/local/bin/remindme` (default)
- installs the user `systemd` unit to `~/.config/systemd/user/remindme.service`

Then enable/start the daemon:

```bash
make systemd-enable
```

Full uninstall (CLI + systemd user unit):

```bash
make uninstall
```

Manual symlink alternative:

```bash
sudo ln -s "$(pwd)/remindme" /usr/local/bin/remindme
```

Then use:

```bash
remindme start
remindme 5m tea
```

## Auto-start on Login (`systemd --user`)

A template unit is included at `systemd/remindme.service`.

Recommended (using `Makefile` helpers):

```bash
make install
```

This generates `~/.config/systemd/user/remindme.service` with your current repo path baked into `ExecStart`.
It also reads `~/.config/remindme.env` automatically if present.

Then enable it:

```bash
make systemd-enable
```

If your repo lives elsewhere (or you want to generate the unit for another path), override `REPO_DIR`:

```bash
make systemd-install REPO_DIR=/home/you/path/to/remind-me-cli
```

Manual setup:

1. Copy it into your user systemd directory:

```bash
mkdir -p ~/.config/systemd/user
cp systemd/remindme.service ~/.config/systemd/user/remindme.service
```

2. Edit `ExecStart` in `~/.config/systemd/user/remindme.service` to match your local path to the `remindme` script.

3. (Recommended) Create `~/.config/remindme.env` with your Discord webhook URL.

4. Reload and enable:

```bash
systemctl --user daemon-reload
systemctl --user enable --now remindme.service
```

5. Check status/logs:

```bash
systemctl --user status remindme.service
journalctl --user -u remindme.service -f
```

Disable / remove the unit later:

```bash
make systemd-disable
make systemd-uninstall
```

## Data Storage

By default, state is stored under:

```bash
~/.local/state/remindme-cli
```

This includes:

- queued jobs
- daemon PID file
- daemon log
- captured environment for notifications

You can override the base path with `XDG_STATE_HOME`.

## Accuracy / Resource Usage

- CPU usage is very low (daemon mostly sleeps)
- RAM usage is low (single Bash process + small job files)
- Notifications may be a few seconds late in worst-case fallback conditions

The daemon is designed to avoid busy polling and wake when new reminders are queued.

## Troubleshooting

Daemon looks stopped:

```bash
./remindme status
./remindme start
```

Discord notifications not sending:

- verify `DISCORD_WEBHOOK_URL`
- verify `curl` is installed
- in `systemd` mode, verify `~/.config/remindme.env` and restart `remindme.service`
- in manual mode, re-run `./remindme start` to refresh captured env

Desktop notifications not showing:

- verify `notify-send` is installed
- ensure you started/queued reminders from your desktop session shell
- restart daemon after login/session changes

## Makefile Targets

```bash
make install
make uninstall
make systemd-install
make systemd-uninstall
make systemd-enable
make systemd-disable
```

Overrides:

```bash
make install PREFIX=$HOME/.local
make install BINDIR=$HOME/.local/bin
make systemd-install REPO_DIR=$HOME/src/remind-me-cli
```

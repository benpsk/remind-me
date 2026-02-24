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

## Install

Use `make` for setup:

```bash
make install
```

Remove everything later (optional):

```bash
make uninstall
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

## Desktop Notification Notes (`notify-send`)

`notify-send` requires your desktop session environment (`DISPLAY`, DBus session vars).

This script captures the relevant environment variables when you run:

- `remindme add ...`
- `remindme every ...`

If desktop notifications stop working after login/session changes, restart the user service:

```bash
systemctl --user restart remindme.service
```

## Commands

Show help:

```bash
./remindme --help
```

Main commands:

```bash
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

Service looks stopped:

```bash
systemctl --user status remindme.service
systemctl --user start remindme.service
```

Discord notifications not sending:

- verify `DISCORD_WEBHOOK_URL`
- verify `curl` is installed
- in `systemd` mode, verify `~/.config/remindme.env` and restart `remindme.service`
- re-run `remindme add ...` or `remindme every ...` to refresh captured env snapshot

Desktop notifications not showing:

- verify `notify-send` is installed
- ensure you started/queued reminders from your desktop session shell
- restart daemon after login/session changes

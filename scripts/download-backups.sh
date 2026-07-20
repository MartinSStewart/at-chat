#!/usr/bin/env bash
#
# download-backups.sh
#
# Downloads new database backups from the at-chat production server over SSH.
# Backups are written by the rust server (see rust-server/src/main.rs) into the
# server's backups folder as files named "backend-export-<timestamp>". This
# script mirrors them to a local folder, only transferring files that aren't
# already present, so it's cheap to run often and safe to run daily.
#
# Usage:
#   scripts/download-backups.sh            Download any new backups now.
#   scripts/download-backups.sh install    Install a daily systemd user timer.
#   scripts/download-backups.sh uninstall  Remove the systemd user timer.
#
# The timer uses Persistent=true, so if the machine is off or asleep at the
# scheduled time, the download runs the next time you log in / power on instead
# of being skipped (unlike cron). Any config values below are baked into the
# unit at install time.
#
# Configuration (override by exporting these before running):
#   REMOTE_HOST        SSH target                (default: root@at-chat.app)
#   REMOTE_BACKUP_DIR  Backups folder on server  (default: /var/lib/atchat/backups/)
#   LOCAL_BACKUP_DIR   Where to save backups     (default: $HOME/at-chat-backups)
#   SSH_KEY            Path to a private key      (default: ssh default)
#   RUN_HOUR           Hour (0-23) for the daily run when installing (default: 4)
#
set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:-root@at-chat.app}"
REMOTE_BACKUP_DIR="${REMOTE_BACKUP_DIR:-/var/lib/atchat/backups/}"
LOCAL_BACKUP_DIR="${LOCAL_BACKUP_DIR:-$HOME/at-chat-backups}"
SSH_KEY="${SSH_KEY:-}"
RUN_HOUR="${RUN_HOUR:-4}"
LOG_FILE="${LOG_FILE:-$LOCAL_BACKUP_DIR/download-backups.log}"

log() {
    local line
    line="$(date '+%Y-%m-%d %H:%M:%S') $*"
    printf '%s\n' "$line" >&2
    # Best-effort append to the log file; never let logging abort the script.
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null && printf '%s\n' "$line" >>"$LOG_FILE" 2>/dev/null || true
}

# Build the ssh command rsync should use, optionally with an explicit key.
ssh_command() {
    if [ -n "$SSH_KEY" ]; then
        printf 'ssh -i %q -o BatchMode=yes -o StrictHostKeyChecking=accept-new' "$SSH_KEY"
    else
        printf 'ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new'
    fi
}

download() {
    mkdir -p "$LOCAL_BACKUP_DIR"

    # Prevent overlapping runs (e.g. a slow transfer still going when cron fires
    # again). flock is a no-op if the lock is already held; we just exit.
    exec 9>"$LOCAL_BACKUP_DIR/.download-backups.lock"
    if ! flock -n 9; then
        log "Another run is already in progress; exiting."
        exit 0
    fi

    log "Downloading new backups from $REMOTE_HOST:$REMOTE_BACKUP_DIR"

    # --ignore-existing: only pull backups we don't already have locally.
    # --partial:         resume interrupted transfers next time.
    # Only fetch the backend-export-* files the server produces.
    if rsync -az --partial --ignore-existing \
        --include='backend-export-*' --exclude='*' \
        -e "$(ssh_command)" \
        "$REMOTE_HOST:$REMOTE_BACKUP_DIR" \
        "$LOCAL_BACKUP_DIR/" >>"$LOG_FILE" 2>&1; then
        log "Done. Backups are in $LOCAL_BACKUP_DIR"
    else
        log "ERROR: rsync failed (see $LOG_FILE)."
        exit 1
    fi
}

UNIT_NAME="at-chat-backups"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

install_systemd() {
    command -v systemctl >/dev/null 2>&1 || {
        log "ERROR: systemctl not found. This system doesn't use systemd."
        exit 1
    }

    local script_path
    script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

    mkdir -p "$UNIT_DIR"

    # Bake the current config into the service so overrides set at install time
    # persist. Only include SSH_KEY if one was provided.
    local key_env=""
    [ -n "$SSH_KEY" ] && key_env="Environment=SSH_KEY=$SSH_KEY"

    cat >"$UNIT_DIR/$UNIT_NAME.service" <<EOF
[Unit]
Description=Download new at-chat backups from $REMOTE_HOST
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
Environment=REMOTE_HOST=$REMOTE_HOST
Environment=REMOTE_BACKUP_DIR=$REMOTE_BACKUP_DIR
Environment=LOCAL_BACKUP_DIR=$LOCAL_BACKUP_DIR
$key_env
ExecStart=$script_path download
EOF

    cat >"$UNIT_DIR/$UNIT_NAME.timer" <<EOF
[Unit]
Description=Daily at-chat backup download

[Timer]
OnCalendar=*-*-* $(printf '%02d' "$RUN_HOUR"):00:00
Persistent=true
RandomizedDelaySec=15min

[Install]
WantedBy=timers.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable --now "$UNIT_NAME.timer"

    log "Installed systemd user timer '$UNIT_NAME.timer' (daily around ${RUN_HOUR}:00)."
    log "Check status: systemctl --user list-timers $UNIT_NAME.timer"
    log "Run now:      systemctl --user start $UNIT_NAME.service"
    log "NOTE: user timers only run while you're logged in. To have it run even"
    log "when logged out, enable lingering: sudo loginctl enable-linger \$USER"
}

uninstall_systemd() {
    command -v systemctl >/dev/null 2>&1 || {
        log "systemctl not found; nothing to remove."
        return 0
    }
    systemctl --user disable --now "$UNIT_NAME.timer" 2>/dev/null || true
    rm -f "$UNIT_DIR/$UNIT_NAME.timer" "$UNIT_DIR/$UNIT_NAME.service"
    systemctl --user daemon-reload
    log "Removed systemd user timer and service."
}

case "${1:-download}" in
    download) download ;;
    install) install_systemd ;;
    uninstall) uninstall_systemd ;;
    *)
        echo "Usage: $0 [download|install|uninstall]" >&2
        exit 2
        ;;
esac

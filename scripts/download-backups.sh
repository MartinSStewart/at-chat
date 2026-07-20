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
#   scripts/download-backups.sh install    Install a daily cron job that runs it.
#   scripts/download-backups.sh uninstall  Remove the cron job.
#
# Configuration (override by exporting these before running, e.g. in the cron
# environment or a wrapper):
#   REMOTE_HOST        SSH target                (default: root@at-chat.app)
#   REMOTE_BACKUP_DIR  Backups folder on server  (default: /var/lib/atchat/backups/)
#   LOCAL_BACKUP_DIR   Where to save backups     (default: $HOME/at-chat-backups)
#   SSH_KEY            Path to a private key      (default: ssh default)
#   RUN_HOUR          Hour (0-23) for the daily run when installing (default: 4)
#
set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:-root@at-chat.app}"
REMOTE_BACKUP_DIR="${REMOTE_BACKUP_DIR:-/var/lib/atchat/backups/}"
LOCAL_BACKUP_DIR="${LOCAL_BACKUP_DIR:-$HOME/at-chat-backups}"
SSH_KEY="${SSH_KEY:-}"
RUN_HOUR="${RUN_HOUR:-4}"
LOG_FILE="${LOG_FILE:-$LOCAL_BACKUP_DIR/download-backups.log}"

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE" >&2
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

install_cron() {
    local script_path
    script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    local cron_line="0 $RUN_HOUR * * * $script_path >/dev/null 2>&1"
    local marker="# at-chat-download-backups"

    # Replace any existing entry for this script, then add the fresh one.
    local current
    current="$(crontab -l 2>/dev/null | grep -v "$marker" || true)"
    printf '%s\n%s %s\n' "$current" "$cron_line" "$marker" | crontab -
    log "Installed daily cron job at ${RUN_HOUR}:00 -> $script_path"
    log "Verify with: crontab -l"
}

uninstall_cron() {
    local marker="# at-chat-download-backups"
    if crontab -l 2>/dev/null | grep -q "$marker"; then
        crontab -l 2>/dev/null | grep -v "$marker" | crontab -
        log "Removed at-chat backup cron job."
    else
        log "No at-chat backup cron job found."
    fi
}

case "${1:-download}" in
    download) download ;;
    install) install_cron ;;
    uninstall) uninstall_cron ;;
    *)
        echo "Usage: $0 [download|install|uninstall]" >&2
        exit 2
        ;;
esac

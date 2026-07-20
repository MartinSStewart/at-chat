# at-chat backup downloader

A small [Eco](https://eco-lang.org/) program — Elm compiled to a native
executable — that downloads any **new** backups from the production server's
backups folder over SSH.

It does a single incremental sync per run and then exits. A **systemd timer**
(or cron) triggers it **once a day**. Keeping the program single-shot means it
survives reboots, never drifts, and can't silently die like a long-lived
process — the scheduler owns "once a day", the Elm program owns "download the
new backups".

The actual transfer is `rsync --ignore-existing` over SSH, so only backup files
that aren't already present locally are downloaded; re-running is cheap.

## What it does

1. Reads its configuration from environment variables (all optional).
2. Checks that `rsync` is installed.
3. Creates the local destination directory if needed.
4. Runs:
   ```
   rsync --archive --compress --partial --ignore-existing --human-readable --stats \
     -e "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=30" \
     root@at-chat.app:/var/lib/atchat/backups/  ./at-chat-backups
   ```
5. Prints a summary and exits `0` on success, or non-zero (rsync's code) on
   failure — so the systemd timer records whether the run worked.

## Configuration

| Environment variable     | Default                                         | Meaning                                   |
| ------------------------ | ----------------------------------------------- | ----------------------------------------- |
| `AT_CHAT_BACKUP_SOURCE`  | `root@at-chat.app:/var/lib/atchat/backups/`     | Remote rsync source (note trailing `/`).  |
| `AT_CHAT_BACKUP_DEST`    | `./at-chat-backups`                             | Local directory to download backups into. |
| `AT_CHAT_SSH_KEY`        | *(unset)*                                       | Path to an SSH private key to use.        |

The remote source default matches `SERVER_BACKUPS_PATH` in
`rust-server/src/main.rs` (`./var/lib/atchat/backups/`). Adjust
`AT_CHAT_BACKUP_SOURCE` if the server's working directory differs.

## Prerequisites

- The [`eco` compiler](https://github.com/eco-lang/eco-compiler) installed (see
  its `docs/getting-started.md`).
- `rsync` and `ssh` on the machine that runs this.
- SSH access to `root@at-chat.app` **without an interactive password** — i.e. a
  key in your ssh-agent, a key referenced by `AT_CHAT_SSH_KEY`, or an entry in
  `~/.ssh/config`. The program runs ssh with `BatchMode=yes`, so a password
  prompt is treated as a failure rather than hanging.

## Build

```
cd scripts/backup-downloader
eco make src/Backup.elm --output=at-chat-backup
```

That produces a native executable `at-chat-backup` in this folder.

> If the first build fails to fetch package sources in a sandboxed environment,
> the same jsDelivr cache trick used elsewhere in this repo applies — see the
> root `CLAUDE.md`.
>
> `elm.json` lists the dependency solution used by `eco/kernel` (elm/core,
> elm/json, elm/time, elm/bytes). If `eco make` reports a missing or invalid
> dependency for your compiler version, copy the `examples/elm.json` shipped with
> the eco distribution (it's a known-good superset) over this one.

## Run manually

```
./at-chat-backup
# or with overrides:
AT_CHAT_BACKUP_DEST=/mnt/backups ./at-chat-backup
```

## Schedule it once a day (systemd — recommended)

Unit files are in [`systemd/`](systemd). To install them as a **user** service
(no root needed):

```
mkdir -p ~/.config/systemd/user
cp systemd/at-chat-backup.service ~/.config/systemd/user/
cp systemd/at-chat-backup.timer   ~/.config/systemd/user/

# Edit the copied .service if your paths/config differ, then:
systemctl --user daemon-reload
systemctl --user enable --now at-chat-backup.timer

# Check it:
systemctl --user list-timers at-chat-backup.timer
journalctl --user -u at-chat-backup.service      # run logs
systemctl --user start at-chat-backup.service    # trigger a run now
```

For a system-wide install, drop the files in `/etc/systemd/system/`, replace the
`%h` paths with absolute ones plus a `User=` line, and use `systemctl` without
`--user`.

The `.service` is `Type=oneshot` and the `.timer` fires daily at 04:00 with
`Persistent=true`, so a missed run (machine off) happens at next boot.

## Schedule it once a day (cron — alternative)

```
crontab -e
```

```cron
0 4 * * * /home/USER/at-chat/scripts/backup-downloader/at-chat-backup >> /home/USER/at-chat-backup.log 2>&1
```

## Files

| File                            | Purpose                                            |
| ------------------------------- | -------------------------------------------------- |
| `src/Backup.elm`                | The program.                                       |
| `elm.json`                      | Eco/Elm dependencies (uses `eco/kernel`).          |
| `systemd/at-chat-backup.service`| One-shot unit that runs the executable.            |
| `systemd/at-chat-backup.timer`  | Daily trigger for the service.                     |

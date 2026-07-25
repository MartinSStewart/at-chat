# at-chat backup downloader

Downloads any **new** backups from the production server's backups folder over
SSH, then checks that the newest backup still decodes and still contains the
same old messages it did last time.

It does a single incremental sync and check per run and then exits. A **systemd
timer** (or cron) triggers it **once a day**. Keeping the program single-shot
means it survives reboots, never drifts, and can't silently die like a
long-lived process — the scheduler owns "once a day", the program owns
"download the new backups and check them".

The actual transfer is `rsync --ignore-existing` over SSH, so only backup files
that aren't already present locally are downloaded; re-running is cheap.

## How it's built

The program is [`src/Backup.elm`](src/Backup.elm), compiled by **Lamdera** and
run by [`run.js`](run.js) on Node.

It used to be an [Eco](https://eco-lang.org/) program — Elm compiled to a native
executable, with direct access to the file system and to subprocesses. Eco can't
compile Lamdera projects, and reading a backup needs the `w3_decode_*` functions
that the Lamdera compiler generates, so the program moved to `lamdera make` and
`run.js` now supplies over ports what `Eco.File`, `Eco.Process` and
`Eco.Console` used to supply directly:

| Port             | Replaces                                 |
| ---------------- | ---------------------------------------- |
| `findExecutable` | `Eco.File.findExecutable`                |
| `dirExists`      | `Eco.File.dirExists`                     |
| `createDir`      | `Eco.File.createDir`                     |
| `runProcess`     | `Eco.Process.spawn` + `Eco.Process.wait` |
| `listDir`        | *(new)* reading the backups folder       |
| `readBackupFile` | *(new)* reading a backup                 |
| `readFile`       | *(new)* reading a reference export       |
| `writeFile`      | *(new)* writing a reference export       |
| `stdout`/`stderr`| `Eco.Console.write`                      |
| `exit`           | `Eco.Process.exit`                       |

Because `Backup.elm` is compiled against the main project it lives in the root
`elm.json`'s source directories, not in its own `elm.json`.

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
5. Decodes the newest `backend-export-*.bin` with
   `WireHelper.foldStreamedBackendModel`, picking a few channels at random as it
   goes (three normal guild channels and three Discord guild channels) and
   exporting each one to JSON with `ChannelExport`, the same code behind the
   "Export channel" button. Failing to decode is itself a failure — it means the
   backup is corrupt, or that this program was built from a different version of
   at-chat than the one that wrote it.
6. Compares each export against that channel's reference export (see below).
7. Prints a summary and exits `0` on success, or non-zero on failure — so the
   systemd timer records whether the run worked.

## Memory

A backup expands to more than twenty times its file size once decoded, so
decoding one into a `BackendModel` and picking through it afterwards runs out of
memory on anything but a small backup: a 21 MB backup peaked at 3.0 GB, most of
it spent turning base64 into `Bytes`.

Two things keep that down. The file crosses the port as `Bytes` rather than
base64, which Lamdera allows and which costs nothing beyond the file itself.
And `foldStreamedBackendModel` throws away the DM channels and hands over one
guild at a time, so the picked channels' exports are all that survive.

That puts the peak in proportion to the largest single guild rather than to the
whole backup — the same 21 MB backup now peaks at 285-475 MB depending on which
channels get picked, and a 58 MB one spread over 20 guilds at around 485 MB. A
single guild holding most of the history is still the worst case, since a guild
has to be decoded in one piece.

## The integrity check

The first time a channel is picked there's nothing to compare against, so its
export is written to `<dest>/reference-exports/` and becomes the reference. On
later runs the fresh export is compared against that file.

Only messages **older than a week** are checked. Recent messages are still being
edited, reacted to and replied to, so they're expected to differ between two
backups; a message from a month ago changing means the backup lost or corrupted
data. Thread messages are dated individually rather than inheriting their
parent's age, so a new reply to an old message doesn't look like the old message
changed.

When a channel passes, its reference is rewritten from the fresh export. Old
messages are identical either way, and it means messages that have since aged
past a week get covered from then on. When a channel fails, its reference is
left alone so the next run compares against the same known-good copy.

Because each run picks a random subset, coverage builds up over time instead of
re-exporting the entire history every day.

One thing to be aware of: the check can't tell data loss apart from someone
legitimately editing or deleting a message that's more than a week old. That's
rare, and a false alarm is cheap — delete that channel's file from
`reference-exports/` and the next run will write a new one.

## Configuration

| Environment variable     | Default                                         | Meaning                                   |
| ------------------------ | ----------------------------------------------- | ----------------------------------------- |
| `AT_CHAT_BACKUP_SOURCE`  | `root@at-chat.app:/var/lib/atchat/backups/`     | Remote rsync source (note trailing `/`).  |
| `AT_CHAT_BACKUP_DEST`    | `./at-chat-backups`                             | Local directory to download backups into. Resolved against the working directory, and printed absolute so a run always says where it put things. |
| `AT_CHAT_SSH_KEY`        | *(unset)*                                       | Path to an SSH private key to use.        |

The remote source default matches `SERVER_BACKUPS_PATH` in
`rust-server/src/main.rs` (`./var/lib/atchat/backups/`). Adjust
`AT_CHAT_BACKUP_SOURCE` if the server's working directory differs.

## Prerequisites

- Node and the repo's npm dependencies (`npm ci` in the repo root).
- `rsync` and `ssh` on the machine that runs this.
- SSH access to `root@at-chat.app` **without an interactive password** — i.e. a
  key in your ssh-agent, a key referenced by `AT_CHAT_SSH_KEY`, or an entry in
  `~/.ssh/config`. The program runs ssh with `BatchMode=yes`, so a password
  prompt is treated as a failure rather than hanging.

## Build and run

From the repo root:

```
npm run backup-downloader
```

That compiles `src/Backup.elm` to `BackupElm.js` and runs it. To build and run
separately:

```
lamdera make scripts/backup-downloader/src/Backup.elm --output scripts/backup-downloader/BackupElm.js
node scripts/backup-downloader/run.js
# or with overrides:
AT_CHAT_BACKUP_DEST=/mnt/backups node scripts/backup-downloader/run.js
```

Rebuild whenever at-chat's `Types.elm` changes, otherwise the program won't be
able to decode backups written by the deployed version.

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
0 4 * * * /usr/bin/node /home/USER/at-chat/scripts/backup-downloader/run.js >> /home/USER/at-chat-backup.log 2>&1
```

## Files

| File                            | Purpose                                                   |
| ------------------------------- | --------------------------------------------------------- |
| `src/Backup.elm`                | The program.                                              |
| `src/ExportComparison.elm`      | Compares a channel export against its reference export.   |
| `run.js`                        | Node host that starts the program and implements its ports.|
| `systemd/at-chat-backup.service`| One-shot unit that runs the program.                      |
| `systemd/at-chat-backup.timer`  | Daily trigger for the service.                            |

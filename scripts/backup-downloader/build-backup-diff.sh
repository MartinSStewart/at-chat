#!/usr/bin/env bash
# Builds backup-diff.js, which compares two backend exports. See the README.
#
#     scripts/backup-downloader/build-backup-diff.sh [commit] [output]
#
# An export only decodes with the codecs of the at-chat version that wrote it, so `commit`
# should be the one that was deployed when the exports were taken (defaults to HEAD). The tool
# is copied into a temporary worktree of that commit and compiled there, which works as long
# as that commit's BackendModel has the fields BackupDiff.elm expects.
set -euo pipefail

repo="$(git rev-parse --show-toplevel)"
commit="${1:-HEAD}"
output="$(realpath -m "${2:-$repo/scripts/backup-downloader/backup-diff.js}")"
lamdera="$(realpath "$repo/node_modules/.bin/lamdera")"
here="$repo/scripts/backup-downloader"

worktree="$(mktemp -d)"
trap 'git -C "$repo" worktree remove --force "$worktree" >/dev/null 2>&1 || rm -rf "$worktree"' EXIT

git -C "$repo" worktree add --detach "$worktree" "$commit" >/dev/null
cp "$here/src/BackupDiff.elm" "$worktree/scripts/backup-downloader/src/BackupDiff.elm"

elm_output="$worktree/backup-diff-elm.js"
(cd "$worktree" && "$lamdera" make scripts/backup-downloader/src/BackupDiff.elm --output "$elm_output")

{
    echo "// Built from at-chat $(git -C "$repo" rev-parse --short "$commit") by build-backup-diff.sh."
    cat "$elm_output"
    cat "$here/backup-diff-runner.js"
} > "$output"

echo "Wrote $output"

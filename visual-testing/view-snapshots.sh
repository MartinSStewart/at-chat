#!/bin/bash
# Starts a browser-based viewer for the snapshots produced by
# run-snapshot-test.sh: every snapshot with its baseline, current and diff
# images side by side (changed ones first).
#
# Compiles the Elm viewer (src/SnapshotViewer.elm) and serves it with
# view-snapshots.js at http://localhost:8878 (override with
# SNAPSHOT_VIEWER_PORT). The manifest is recomputed on every page load, so you
# can leave this running, re-run the snapshot test, and just refresh.
set -e

cd "$(dirname "$0")"
vt_dir=$(pwd)
repo_root=$(git rev-parse --show-toplevel)

current_dir="$vt_dir/snapshots/current"
diff_dir="$vt_dir/snapshots/diff"

# Find the baseline folder the same way run-snapshot-test.sh names it
# (baseline-<merge-base sha>); fall back to the most recently written
# baseline-* folder if that exact one doesn't exist.
baseline_dir=""
if git rev-parse --verify --quiet master >/dev/null; then
  base_branch=master
elif git rev-parse --verify --quiet main >/dev/null; then
  base_branch=main
else
  base_branch=""
fi
if [ -n "$base_branch" ]; then
  base_sha=$(git merge-base "$base_branch" HEAD 2>/dev/null || true)
  if [ -n "$base_sha" ] && [ -d "$vt_dir/snapshots/baseline-$base_sha" ]; then
    baseline_dir="$vt_dir/snapshots/baseline-$base_sha"
  fi
fi
if [ -z "$baseline_dir" ]; then
  baseline_dir=$(ls -dt "$vt_dir"/snapshots/baseline-*/ 2>/dev/null | head -n 1)
  baseline_dir=${baseline_dir%/}
fi
if [ -z "$baseline_dir" ]; then
  # Nothing rendered yet for the baseline; point at the canonical (missing)
  # path so the viewer still works for current-only snapshots.
  baseline_dir="$vt_dir/snapshots/baseline-none"
fi

if [ ! -d "$current_dir" ] && [ ! -d "$baseline_dir" ]; then
  echo "❌ No snapshots found in $vt_dir/snapshots. Run ./run-snapshot-test.sh first." >&2
  exit 1
fi

# Install this folder's node deps if missing (express, ...).
if [ ! -d node_modules/express ]; then
  echo "Installing visual-testing node dependencies..."
  npm install
fi

echo "🔨 Compiling snapshot viewer..."
(
  cd "$repo_root"
  if command -v lamdera >/dev/null 2>&1; then
    lamdera make visual-testing/src/SnapshotViewer.elm --output=visual-testing/dist/snapshot-viewer.js
  else
    npx --yes lamdera make visual-testing/src/SnapshotViewer.elm --output=visual-testing/dist/snapshot-viewer.js
  fi
)

port="${SNAPSHOT_VIEWER_PORT:-8878}"

# Best effort: pop the viewer open in the default browser once the server is
# up. Harmless when no opener exists (headless/CI).
(
  sleep 1
  xdg-open "http://localhost:$port" >/dev/null 2>&1 \
    || open "http://localhost:$port" >/dev/null 2>&1 \
    || true
) &

node view-snapshots.js "$baseline_dir" "$current_dir" "$diff_dir"

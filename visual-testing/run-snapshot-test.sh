#!/bin/bash
# Visual snapshot regression test.
#
# 1. Refuse to run on master/main (you must be on a feature branch).
# 2. Render snapshots of the current feature branch.
# 3. Check out the commit on master that this feature branch forked from
#    (in a throwaway git worktree, so your branch and working tree are never
#    touched) and render baseline snapshots there.
# 4. The worktree is removed, leaving you exactly where you started.
# 5. Diff current vs baseline and list which snapshots don't match.
#
# Pass --view to open the result viewer (view-snapshots.sh) when done.
#
# Baselines are cached per base commit in snapshots/baseline-<sha>/, so steps
# 3 and 4 are skipped when that folder already exists.
set -e

cd "$(dirname "$0")"
vt_dir=$(pwd)
repo_root=$(git rev-parse --show-toplevel)

# --- 1. Must be on a feature branch ----------------------------------------
branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" = "master" ] || [ "$branch" = "main" ] || [ "$branch" = "HEAD" ]; then
  echo "❌ You are on '$branch'. Check out a feature branch before running visual snapshot tests." >&2
  exit 1
fi

# Pick whichever of master/main exists locally as the integration branch.
if git rev-parse --verify --quiet master >/dev/null; then
  base_branch=master
elif git rev-parse --verify --quiet main >/dev/null; then
  base_branch=main
else
  echo "❌ Could not find a local 'master' or 'main' branch to compare against." >&2
  exit 1
fi

base_sha=$(git merge-base "$base_branch" HEAD)
echo "ℹ️  Feature branch : $branch"
echo "ℹ️  Base ($base_branch) : $base_sha"

current_dir="$vt_dir/snapshots/current"
baseline_dir="$vt_dir/snapshots/baseline-$base_sha"
diff_dir="$vt_dir/snapshots/diff"

# Guarded `rm -rf`. Refuses to delete anything that isn't strictly inside this
# repo's snapshots/ folder, so a bug that leaves a path variable empty (e.g.
# "$vt_dir" unset turning "$diff_dir" into the root-anchored "/snapshots/diff")
# can never blow away an unexpected directory.
safe_rmrf() {
  local target="$1"
  if [ -z "$vt_dir" ] || [ -z "$target" ]; then
    echo "❌ safe_rmrf: refusing to delete (empty path; vt_dir='$vt_dir' target='$target')" >&2
    exit 1
  fi
  case "$target" in
    "$vt_dir/snapshots/"?*) rm -rf "$target" ;;
    *)
      echo "❌ safe_rmrf: refusing to delete '$target' (not inside '$vt_dir/snapshots/')" >&2
      exit 1
      ;;
  esac
}

# Install this folder's node deps if missing (webdriverio, esbuild, odiff, ...).
if [ ! -d node_modules/webdriverio ]; then
  echo "Installing visual-testing node dependencies..."
  npm install
fi

# render_snapshots <repo-dir> <output-dir>
# Compiles the harness inside <repo-dir> and renders all snapshots into the
# absolute <output-dir>.
render_snapshots() {
  local repo_dir="$1"
  local out="$2"
  safe_rmrf "$out"
  (
    cd "$repo_dir"
    if command -v lamdera >/dev/null 2>&1; then
      LDEBUG=1 lamdera make visual-testing/src/SnapshotHarness.elm --output=visual-testing/snapshot-harnessed-app.js
    else
      LDEBUG=1 npx --yes lamdera make visual-testing/src/SnapshotHarness.elm --output=visual-testing/snapshot-harnessed-app.js
    fi
    cp visual-testing/snapshot-harnessed-app.js visual-testing/dist/snapshot-harnessed-app.js
    ( cd visual-testing/dist && npx esbuild harness.js --entry-names="harness-compiled" --bundle --minify --outdir=. )
    ( cd visual-testing && SNAPSHOT_OUT="$out" node runner-candidate-harness.js )
  )
}

# --- 2. Render current branch snapshots ------------------------------------
echo ""
echo "📸 Rendering current branch snapshots..."
render_snapshots "$repo_root" "$current_dir"

# --- 3. Render baseline snapshots for the base commit (cached) --------------
if [ -d "$baseline_dir" ] && [ -n "$(ls -A "$baseline_dir" 2>/dev/null)" ]; then
  echo ""
  echo "✅ Reusing cached baseline for $base_sha"
else
  echo ""
  echo "📸 Rendering baseline snapshots for base commit $base_sha..."
  worktree=$(mktemp -d "${TMPDIR:-/tmp}/at-chat-baseline.XXXXXX")
  # Always clean up the worktree, even on error / Ctrl-C (this is step 4).
  cleanup() {
    git -C "$repo_root" worktree remove --force "$worktree" >/dev/null 2>&1 || true
    rm -rf "$worktree" 2>/dev/null || true
  }
  trap cleanup EXIT

  # Detached worktree at the base commit: leaves your branch + working tree
  # completely untouched.
  git -C "$repo_root" worktree add --quiet --detach "$worktree" "$base_sha"

  # Render the BASE app code with the CURRENT test tooling (runner + harness),
  # so a difference in the test infrastructure can never masquerade as a visual
  # diff. Overlay the current visual-testing tooling onto the base checkout.
  mkdir -p "$worktree/visual-testing/src" "$worktree/visual-testing/dist"
  cp runner-candidate-harness.js "$worktree/visual-testing/runner-candidate-harness.js"
  cp marktimer.js                "$worktree/visual-testing/marktimer.js"
  cp src/SnapshotHarness.elm      "$worktree/visual-testing/src/SnapshotHarness.elm"
  cp dist/harness.html            "$worktree/visual-testing/dist/harness.html"
  cp dist/harness.js              "$worktree/visual-testing/dist/harness.js"
  # Reuse the already-installed node modules instead of reinstalling.
  ln -s "$vt_dir/node_modules"   "$worktree/visual-testing/node_modules"
  ln -s "$repo_root/node_modules" "$worktree/node_modules"
  # Make sure the base elm.json exposes visual-testing/src as a source dir
  # (older base commits may predate the snapshot harness).
  node -e '
    const fs = require("fs");
    const p = process.argv[1];
    const j = JSON.parse(fs.readFileSync(p, "utf8"));
    if (!j["source-directories"].includes("visual-testing/src")) {
      j["source-directories"].push("visual-testing/src");
      fs.writeFileSync(p, JSON.stringify(j, null, 4));
    }
  ' "$worktree/elm.json"

  render_snapshots "$worktree" "$baseline_dir"

  cleanup
  trap - EXIT
fi

# --- 5. Diff current vs baseline -------------------------------------------
echo ""
echo "🔍 Comparing current branch against baseline..."
safe_rmrf "$diff_dir"
compare_status=0
node compare-snapshots.js "$baseline_dir" "$current_dir" "$diff_dir" || compare_status=$?

# --- 6. Optionally start the result viewer ----------------------------------
if [ "${1:-}" = "--view" ]; then
  ./view-snapshots.sh
else
  echo ""
  echo "👀 Run ./view-snapshots.sh (or re-run with --view) to browse the images in a browser."
fi
exit $compare_status

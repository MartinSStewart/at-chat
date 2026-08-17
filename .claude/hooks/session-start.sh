#!/bin/bash
# Prepares a fresh Claude Code on the web container so that `lamdera make`,
# `elm-test-rs` and `elm-review` all work on the first try.
#
# Web sessions start from a clean container every time, so both of these have to
# happen once per session:
#   * node_modules (lamdera, elm-format, elm-test-rs and elm-review live there)
#   * the Elm package cache, which the sandbox's egress policy stops the
#     compiler from filling itself (see scripts/populate-elm-cache.py)
set -euo pipefail

# Local machines already have a working setup; only the web containers need this.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# `install` rather than `ci` so an already-warm container skips the work.
npm install --no-audit --no-fund

# Covers elm.json and review/elm.json. Skips packages already in the cache.
python3 scripts/populate-elm-cache.py

# elm-review solves its own dependencies and only writes that solve to disk when it
# runs, so the first run is the one that discovers what else the cache is missing —
# and the one that creates the separate docs cache the second populate fills in for
# the lamdera packages. Get that over with here rather than in the middle of
# someone's work: run it once (expected to fail), then fill in what it asked for.
npx elm-review --compiler "$(realpath node_modules/.bin/lamdera)" >/dev/null 2>&1 || true
python3 scripts/populate-elm-cache.py

#!/bin/bash
set -ex

return=$(pwd)

# Use a globally installed `lamdera` if available (e.g. macOS via the official
# installer), otherwise fall back to the `lamdera` npm package via npx so this
# works out of the box on Linux where lamdera is typically not on the PATH.
if command -v lamdera >/dev/null 2>&1; then
  LAMDERA="lamdera"
else
  LAMDERA="npx --yes lamdera"
fi

# project=~/dev/projects/lamdera-dashboard
# project=~/dev/projects/realia-app

# If we were to test against another app that implemented SnapshotRunner.snapshots

# cd $project
# cp $return/src/SnapshotHarness.elm src/SnapshotHarness.elm
# LDEBUG=1 lamdera make src/SnapshotHarness.elm --output=snapshot-harnessed-app.js
# cp snapshot-harnessed-app.js $return/dist/snapshot-harnessed-app.js
# cd $return

cd ..
LDEBUG=1 $LAMDERA make visual-testing/src/SnapshotHarness.elm --output=visual-testing/snapshot-harnessed-app.js
cd visual-testing
cp snapshot-harnessed-app.js dist/snapshot-harnessed-app.js

cd dist
npx esbuild harness.js --entry-names="harness-compiled" --bundle --minify --outdir=. 2>&1

cd "$return"

time node runner-candidate-harness.js

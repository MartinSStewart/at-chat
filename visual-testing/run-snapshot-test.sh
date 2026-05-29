#!/bin/bash
set -ex

return=$(pwd)

# project=~/dev/projects/lamdera-dashboard
# project=~/dev/projects/realia-app

# If we were to test against another app that implemented SnapshotRunner.snapshots

# cd $project
# cp $return/src/SnapshotHarness.elm src/SnapshotHarness.elm
# LDEBUG=1 lamdera make src/SnapshotHarness.elm --output=snapshot-harnessed-app.js
# cp snapshot-harnessed-app.js $return/dist/snapshot-harnessed-app.js
# cd $return

cd ..
LDEBUG=1 lamdera make visual-testing/src/SnapshotHarness.elm --output=visual-testing/snapshot-harnessed-app.js
cd visual-testing
cp snapshot-harnessed-app.js dist/snapshot-harnessed-app.js

cd dist
npx esbuild harness.js --entry-names="harness-compiled" --bundle --minify --outdir=. 2>&1

cd "$return"

time node runner-candidate-harness.js

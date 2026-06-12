/*

Serves the snapshot viewer (an Elm app, src/SnapshotViewer.elm) for browsing
the results of run-snapshot-test.sh: every snapshot with its baseline, current
and diff images side by side.

Usage:
  node view-snapshots.js <baselineDir> <currentDir> <diffDir>

The manifest is recomputed from disk on every request, so re-running the
snapshot test and refreshing the browser is enough to see fresh results.

Started by view-snapshots.sh, which also compiles the Elm viewer.

*/

const express = require("express");
const fs = require("fs");
const path = require("path");

const [, , baselineDir, currentDir, diffDir] = process.argv;

if (!baselineDir || !currentDir || !diffDir) {
  console.error("Usage: node view-snapshots.js <baselineDir> <currentDir> <diffDir>");
  process.exit(2);
}

const port = parseInt(process.env.SNAPSHOT_VIEWER_PORT || "8878", 10);

const pngsIn = (dir) =>
  fs.existsSync(dir)
    ? fs.readdirSync(dir).filter((f) => f.toLowerCase().endsWith(".png"))
    : [];

const app = express();
app.disable("x-powered-by");

app.get("/manifest.json", (req, res) => {
  const baseline = new Set(pngsIn(baselineDir));
  const current = new Set(pngsIn(currentDir));
  const diff = new Set(pngsIn(diffDir));
  const names = [...new Set([...baseline, ...current])].sort();
  res.json({
    baselineName: path.basename(baselineDir),
    snapshots: names.map((name) => ({
      name,
      inBaseline: baseline.has(name),
      inCurrent: current.has(name),
      hasDiff: diff.has(name),
    })),
  });
});

app.use("/images/baseline", express.static(path.resolve(baselineDir)));
app.use("/images/current", express.static(path.resolve(currentDir)));
app.use("/images/diff", express.static(path.resolve(diffDir)));
app.use(express.static(path.join(__dirname, "dist")));

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "dist", "viewer.html"), { cacheControl: false });
});

app.listen(port, () => {
  console.log(`\n👀 Snapshot viewer running at http://localhost:${port}`);
  console.log(`   baseline: ${baselineDir}`);
  console.log(`   current : ${currentDir}`);
  console.log(`   diff    : ${diffDir}`);
  console.log("   Ctrl-C to stop.");
});

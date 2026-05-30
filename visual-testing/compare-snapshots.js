/*

Compares two folders of snapshot PNGs (baseline vs current) and writes a diff
mask per changed snapshot. Exits non-zero if any snapshot differs, is missing,
or is newly added, so the run is usable as a pass/fail check.

Usage:
  node compare-snapshots.js <baselineDir> <currentDir> <diffDir>

*/

const { compare } = require("odiff-bin");
const fs = require("fs");
const path = require("path");

const [, , baselineDir, currentDir, diffDir] = process.argv;

if (!baselineDir || !currentDir || !diffDir) {
  console.error("Usage: node compare-snapshots.js <baselineDir> <currentDir> <diffDir>");
  process.exit(2);
}

fs.mkdirSync(diffDir, { recursive: true });

const pngsIn = (dir) =>
  fs.existsSync(dir)
    ? fs.readdirSync(dir).filter((f) => f.toLowerCase().endsWith(".png"))
    : [];

const baseline = new Set(pngsIn(baselineDir));
const current = new Set(pngsIn(currentDir));
const allNames = new Set([...baseline, ...current]);

(async () => {
  const changed = [];
  const added = [];
  const removed = [];

  for (const name of [...allNames].sort()) {
    const inBaseline = baseline.has(name);
    const inCurrent = current.has(name);

    if (inBaseline && !inCurrent) {
      removed.push(name);
      continue;
    }
    if (!inBaseline && inCurrent) {
      added.push(name);
      continue;
    }

    const { match, reason } = await compare(
      path.join(baselineDir, name),
      path.join(currentDir, name),
      path.join(diffDir, name),
      { outputDiffMask: true }
    );
    if (!match) {
      changed.push({ name, reason });
    }
  }

  const total = changed.length + added.length + removed.length;

  if (total === 0) {
    console.log(`\n✅ All ${current.size} snapshot(s) match the baseline`);
    process.exit(0);
  }

  console.log(`\n❌ ${total} snapshot(s) differ from the baseline:`);
  changed.forEach(({ name, reason }) =>
    console.log(`   ~ changed: ${name} (${reason}) -> ${path.join(diffDir, name)}`)
  );
  added.forEach((name) => console.log(`   + added (no baseline): ${name}`));
  removed.forEach((name) => console.log(`   - removed (only in baseline): ${name}`));
  process.exit(1);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});

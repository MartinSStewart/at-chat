## Visual snapshot testing

Compiles the Elm app through a snapshot harness, drives a headless Chrome via
WebdriverIO, and saves one PNG per snapshot defined in the recorded tests.

### Deps

Install the node dependencies in this folder:

```bash
npm i
```

(`run-snapshot-test.sh` also runs this automatically if `node_modules` is
missing, so you can usually skip it.)

You also need the project's root dependencies installed (run `npm i` in the
repository root) so the Elm build's esbuild step is available.

#### Linux notes

- Most desktop installs already have the shared libraries headless Chrome
  needs. On a minimal/CI image you may need to install them — the simplest
  way is to let `apt` pull in everything Chrome depends on:

  ```bash
  # Adds the Google repo, then installs Chrome + all of its runtime deps.
  wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt-get update && sudo apt-get install -y /tmp/chrome.deb
  ```

  (You don't need Chrome itself for the test — WebdriverIO downloads its own —
  but this is a reliable way to get the right system libraries regardless of
  distro/version, where individual `lib*` package names differ.)
- Chrome is started with `--no-sandbox` and `--disable-dev-shm-usage` so it
  runs headless as root / inside containers. These flags are set in
  `runner-candidate-harness.js` and are harmless on macOS.

### Running

```bash
./run-snapshot-test.sh
```

This compares the visual output of your **current feature branch** against the
point on `master` it branched from, so you can see exactly which snapshots your
branch changed. Concretely it:

1. Refuses to run if you're on `master`/`main` — you must be on a feature
   branch (this is what defines "what changed").
2. Renders snapshots of your current branch into `snapshots/current/`.
3. Finds the commit on `master` your branch forked from
   (`git merge-base master HEAD`), checks it out in a throwaway **git
   worktree**, and renders baseline snapshots into
   `snapshots/baseline-<sha>/`. Your branch, working tree and uncommitted
   changes are never touched. To keep the base/current comparison fair, the
   base app code is rendered with the *current* test harness + runner (only the
   app/test code differs, not the tooling).
4. Removes the worktree, leaving you exactly where you started.
5. Diffs `current/` against `baseline-<sha>/` with
   [`odiff`](https://github.com/dmtrKovalenko/odiff), writing a diff mask per
   changed snapshot into `snapshots/diff/` and printing which snapshots changed
   (or were added / removed). Exits non-zero if anything differs, so it's
   usable as a pass/fail check.

Baselines are cached per base commit (`snapshots/baseline-<sha>/`), so steps 3
and 4 are skipped on repeat runs against the same base. Delete that folder (or
the whole `snapshots/` folder) to force a fresh baseline. Everything under
`snapshots/` is gitignored.

```
$ ls snapshots
baseline-2460e7e…/   current/   diff/
```

It compiles the Elm app via `lamdera` (falling back to `npx lamdera` when
lamdera isn't on your `PATH`), esbuilds the harness, then renders.

### Viewing the results

```bash
./view-snapshots.sh        # or: ./run-snapshot-test.sh --view
```

Starts a viewer at <http://localhost:8878> (override with
`SNAPSHOT_VIEWER_PORT`) that shows every snapshot with its baseline, current
and diff images side by side — no folder digging needed. Changed snapshots are
listed first; the diff column overlays the odiff mask on the current image so
you can see *where* the change is, and clicking any image opens the raw PNG.
Unchanged snapshots are hidden by default (toggle in the header, along with an
image-size slider).

The viewer itself is an Elm app (`src/SnapshotViewer.elm`) compiled by the
script and served by `view-snapshots.js`. The snapshot list is re-read from
disk on every page load, so you can leave it running, re-run the snapshot
test, and just refresh the browser.

## Visual snapshot testing

Renders every snapshot in the E2E tests to a PNG and shows which ones your
branch changed, compared against the point on `master` it branched from.

### Running

From the repository root, on a feature branch (it refuses to run on
`master`/`main`):

```bash
npm run snapshot-chrome     # or snapshot-firefox, snapshot-safari
```

This renders your branch, renders the base commit in a throwaway git worktree
(your working tree is never touched), diffs the two, and opens a viewer at
<http://localhost:8878> showing baseline, current and diff side by side with
the changed snapshots first. It exits non-zero if anything changed, so it also
works as a pass/fail check.

From this folder the same thing is
`SNAPSHOT_BROWSER=firefox ./run-snapshot-test.sh --view`, and
`./view-snapshots.sh` reopens the viewer on the last results.

### Setup

Run `npm i` in the repository root. This folder's dependencies are installed
for you on first run. Then, depending on the browser:

- **chrome** — nothing to install, WebdriverIO downloads Chrome and
  chromedriver. On a bare Linux image Chrome's system libraries may be missing;
  installing Google's `.deb` is the easiest way to pull them all in.
- **firefox** — install Firefox yourself; WebdriverIO only downloads the
  driver. Without it you get `Couldn't find a matching firefox browser`.
- **safari** — macOS only, and `safaridriver --enable` has to have been run
  once. It has no headless mode, so a real Safari window drives on your screen:
  don't lock the Mac mid-run, and expect 2× images on a Retina display.

### Notes

- Rendering starts with one call that simulates the whole E2E test suite before
  the first snapshot exists. It takes minutes (Chrome on a Linux desktop: ~90s;
  Firefox is several times slower, and a laptop slower again) and blocks the
  browser's JS thread throughout, so nothing is printed but the elapsed-time
  ticker. If a machine is slow enough to run past the 30 minute budget the run
  fails with a timeout; give it more with
  `SNAPSHOT_FIRST_ADVANCE_TIMEOUT=3600000 npm run snapshot-firefox` (ms).
- Baselines are cached per browser and base commit. Delete `snapshots/` to
  force fresh ones; everything in there is gitignored.
- Each browser draws text slightly differently and gets its own snapshot
  folder, so switching browsers re-renders the baseline rather than reporting
  every snapshot as changed.
- The browser only rasterises the DOM. What the *app* believes it's running in
  comes from the user agent the test passes to `load_startup_data_from_js`
  (`E2EHelper.firefoxDesktop`, `safariIphone`, ...).
- Bump `renderer_version` in `run-snapshot-test.sh` after changing the runner in
  a way that changes the images, so cached baselines get re-rendered instead of
  compared against.

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

- Will compile the Elm app (via `lamdera`/`npx lamdera`)
- Will esbuild the harness
- Will run the harness, which outputs PNGs to the `./snapshots` folder.

On the first run every snapshot is written as a `*-baseline.png` (the
`snapshots` folder is created automatically and is gitignored):

```
$ ls snapshots
"Test login: homepage-baseline.png"  "Test login: login-baseline.png"  ...
```

On subsequent runs each snapshot is captured as `*-actual.png` and compared
against its baseline using [`odiff`](https://github.com/dmtrKovalenko/odiff),
writing a `*-odiff.png` diff mask when they differ.
/*

Harness version of runner-candidate.js

Render-only: boots the compiled snapshot harness in a headless browser and
writes one PNG per snapshot into SNAPSHOT_OUT (default: ./snapshots).

It does NOT compare against a baseline - that is done separately by
compare-snapshots.js so that the same rendering code can be used to produce
both the "current" and the "baseline" (base commit) images. See
run-snapshot-test.sh for the orchestration.

*/

const { remote } = require('webdriverio')
const { join } = require('path');
const { markTime } = require('./marktimer')
const fs = require("fs");

const http = require('http')
const express = require('express')
const bodyParser = require('body-parser')
const sanitize = require("sanitize-filename");

const port = parseInt(process.env.SNAPSHOT_PORT || '8877', 10)
const outDir = process.env.SNAPSHOT_OUT || 'snapshots'
const projectAssets = '../public'

// Which browser renders the snapshots (SNAPSHOT_BROWSER, default chrome).
// webdriverio fetches the matching driver itself. It also downloads Chrome, but
// Firefox has to be installed already (its download fallback only knows how to
// fetch Nightly, from a URL that no longer resolves), and Safari is whatever
// Safari the Mac has. See readme.md.
const browserCapabilities = {
  chrome: {
    browserName: 'chrome',
    // --no-sandbox and --disable-dev-shm-usage are required to run headless
    // Chrome on Linux (especially as root / in CI containers). They are
    // harmless on macOS, so we always pass them to keep this cross-platform.
    'goog:chromeOptions': { args: ['--headless=new', '--disable-gpu', '--no-sandbox', '--disable-dev-shm-usage'] },
  },
  firefox: {
    browserName: 'firefox',
    'moz:firefoxOptions': { args: ['-headless'] },
  },
  safari: {
    // safaridriver has no headless mode, so this drives a real Safari window
    // on a real screen. macOS only, and `safaridriver --enable` must have been
    // run once.
    browserName: 'safari',
  },
}[process.env.SNAPSHOT_BROWSER || 'chrome']

if (!browserCapabilities) {
  console.error(`❌ Unknown SNAPSHOT_BROWSER '${process.env.SNAPSHOT_BROWSER}' (expected chrome, firefox or safari)`)
  process.exit(2)
}

// webdriverio's saveScreenshot throws if the target directory doesn't exist.
fs.mkdirSync(outDir, { recursive: true })


var app = express()
app.disable('x-powered-by')

// Top level error handling
app.use((err, req, res, next) => {
  if (!err) { return next() }
  res.status(500)
  res.send('500: Internal server error')
})

// Limit is extended for hoisting which POSTS the backend model in postRedirectMsg
app.use(bodyParser.json({limit: '100mb', strict: false}))
// For application/x-www-form-urlencoded headers
app.use(bodyParser.urlencoded({ extended: true }))
// https://github.com/expressjs/body-parser#bodyparserrawoptions
// @SECURITY we could improve DDOS surface here by using `verify` to check first few bits?
app.use(bodyParser.raw({inflate: true, limit: '100mb', type: 'application/octet-stream'}))
app.use(express.static('dist'))
app.use(express.static('..'))

// @TODO paramaterise this for the project folder
app.use(express.static(projectAssets))

// Final catch-all route
app.get('/*', (req, res) => {
  console.log('serving', join(process.cwd(), '/dist/harness.html'))
  res.sendFile(join(process.cwd(), '/dist/harness.html'), { cacheControl: false })
})

const server = http.createServer(app)
server.listen(port, () => {
  console.log(`✅ listening on http://127.0.0.1:${port}`)
});


(async () => {
    markTime("boot")
    // The first advanceSnapshotRequested below blocks for as long as it takes to
    // simulate the whole test suite (minutes). webdriverio gives up on a command
    // after connectionRetryTimeout (2 minutes by default) and then RETRIES it,
    // which is silent and destructive here: the retry sends a second advance, so
    // the harness steps past a snapshot that never got photographed. Firefox is
    // slow enough at the simulation to cross the 2 minute default and lose the
    // first snapshot every run; Chrome sneaks in just under it. Wait long enough
    // for the simulation, and never retry - a lost command should be an error, not
    // a quietly missing image.
    let browser = await remote({
      capabilities: browserCapabilities,
      connectionRetryTimeout: 600000,
      connectionRetryCount: 0,
    });
    markTime("remote")

    await browser.navigateTo(`http://localhost:${port}`);

    await browser.waitUntil(async function () {
      const state = await browser.execute(function () {
        return document.readyState;
      });
      console.log("state:" + state)
      return state === 'complete';
    },
    {
      timeout: 3000, //60secs
      timeoutMsg: 'Oops! Check your internet connection'
    });

    markTime("browser ready")

    var snapshot = { hasMore: true }

    // The first advanceSnapshotRequested is special: the harness only responds
    // once the test data files have loaded AND the entire test suite has been
    // simulated (T.toSnapshots), which takes minutes and grows as tests are
    // added. This is the browser-side half of the budget for it (the client-side
    // half is connectionRetryTimeout above); if it runs out the browser aborts
    // the script and the first snapshot is lost.
    await browser.setTimeout({ script: 300000 })

    // Web fonts (e.g. the app's Montserrat @font-face, declared with
    // `font-display: swap`) are fetched lazily and can finish *after* the page
    // load event. A screenshot taken in that window captures fallback-font text
    // and produces a spurious diff. Before each screenshot we force every
    // declared font face to load and then await document.fonts.ready, so the
    // render is deterministic regardless of network timing.
    async function waitForFonts() {
      await browser.executeAsync(function (done) {
        var loads = [];
        document.fonts.forEach(function (face) {
          if (face.status !== 'loaded') {
            // .load() resolves once the face's file is fetched; swallow
            // failures (e.g. a face whose file 404s) so one bad font can't
            // hang the whole run.
            loads.push(face.load().catch(function () {}));
          }
        });
        Promise.all(loads)
          .then(function () { return document.fonts.ready; })
          .then(function () { done(); }, function () { done(); });
      });
    }

    // Elm renders in an animation frame, and `respondReadyForSnapshot` is a Cmd
    // dispatched from `update`, so when the advance below resolves the page is
    // still showing the PREVIOUS snapshot; Elm draws the new one a frame later.
    // Screenshotting in that window saves the previous snapshot's picture under
    // the new snapshot's name. Since consecutive snapshots often come from
    // different tests, the result doesn't look like a timing artifact at all -
    // e.g. snapshot 103 is a Go board and 104 is a word spelling game, so the
    // word spelling game's file ends up with a picture of a Go board in it.
    // document.title carries the index of the snapshot Elm has actually drawn,
    // so wait for it to match before screenshotting. Chrome usually redraws
    // fast enough to hide the gap; Firefox regularly loses this race.
    async function waitForRender(index) {
      await browser.waitUntil(
        async function () { return (await browser.getTitle()) === `snapshot-${index}` },
        {
          timeout: 30000,
          interval: 50,
          timeoutMsg: `Timed out waiting for snapshot ${index} to be rendered`,
        }
      );
      // The title is set right after the DOM patch, so the page now holds the
      // right elements; give the browser one frame to actually paint them.
      await browser.executeAsync(function (done) {
        requestAnimationFrame(function () { requestAnimationFrame(function () { done(); }); });
      });
    }

    snapshot = await browser.executeAsync(function(readyForSnapshotCallback) {
      window.advanceSnapshotRequested(readyForSnapshotCallback)
    });

    // Every later advance just steps to an already-simulated snapshot (a few
    // milliseconds). This budget covers each executeAsync below, including
    // waiting for web fonts to load before a screenshot.
    await browser.setTimeout({ script: 60000 })

    var count = 0

    while (snapshot.hasMore) {
      // @TODO security
      // snapshotName = sanitize(snapshotName);
      await browser.setWindowSize(snapshot.width, snapshot.height);
      await waitForRender(snapshot.index);
      await waitForFonts();
      await browser.saveScreenshot(`${outDir}/${snapshot.name}.png`);
      count++;

      snapshot = await browser.executeAsync(function(readyForSnapshotCallback) {
        window.advanceSnapshotRequested(readyForSnapshotCallback)
      });
    }

    await browser.deleteSession()

    console.log(`📸 Wrote ${count} snapshot(s) to ${outDir}`)
    process.exit(0)

})().catch((err) => {
    console.error(err)
    browser.deleteSession()
    process.exit(1)
})

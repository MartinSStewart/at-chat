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
    let browser = await remote({
      capabilities: { browserName: 'chrome',
        // --no-sandbox and --disable-dev-shm-usage are required to run headless
        // Chrome on Linux (especially as root / in CI containers). They are
        // harmless on macOS, so we always pass them to keep this cross-platform.
        'goog:chromeOptions': { args: ['--headless=new', '--disable-gpu', '--no-sandbox', '--disable-dev-shm-usage'] },
      },
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

    await browser.setTimeout({ script: 2000 })

    snapshot = await browser.executeAsync(function(readyForSnapshotCallback) {
      window.advanceSnapshotRequested(readyForSnapshotCallback)
    });

    var count = 0

    while (snapshot.hasMore) {
      // @TODO security
      // snapshotName = sanitize(snapshotName);
      browser.setWindowSize(snapshot.width, snapshot.height);
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

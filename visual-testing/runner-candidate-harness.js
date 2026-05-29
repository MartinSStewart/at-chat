/*

Harness version of runner-candidate.js

*/

const { remote } = require('webdriverio')
const { join } = require('path');
const { markTime } = require('./marktimer')
const { compare } = require("odiff-bin");
const fs = require("fs");

const http = require('http')
const express = require('express')
const bodyParser = require('body-parser')
const sanitize = require("sanitize-filename");

// @TODO paramaterise
const port = 8877
const projectAssets = '../public'


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
        'goog:chromeOptions': { args: ['headless', 'disable-gpu'] },
      },
    });
    markTime("remote")

    await browser.navigateTo("http://localhost:8877");

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

    while (snapshot.hasMore) {
      // @TODO security
      // snapshotName = sanitize(snapshotName);
      browser.setWindowSize(snapshot.width, snapshot.height);
      var exists = false;
      try {
        // exists = await fs.promises.access(join(process.cwd(), `/snapshots/${snapshot.name}-baseline.png`), fs.constants.F_OK)
        exists = fs.existsSync(`snapshots/${snapshot.name}-baseline.png`)
      } catch(err) {
        exists = false;
      }

      if (exists) {

        // console.log("Saving actual: ", `snapshots/${snapshot.name}-actual.png`)
        await browser.saveScreenshot(`snapshots/${snapshot.name}-actual.png`);
        // markTime("actual screenshot")

        // const { match, reason } = await
        compare(
          `snapshots/${snapshot.name}-baseline.png`,
          `snapshots/${snapshot.name}-actual.png`,
          `snapshots/${snapshot.name}-odiff.png`,
          { outputDiffMask: true }
        );
        // markTime("odiff")

      } else {
        console.log("Setting baseline: ", `snapshots/${snapshot.name}-baseline.png`)
        await browser.saveScreenshot(`snapshots/${snapshot.name}-baseline.png`);
      }

      snapshot = await browser.executeAsync(function(readyForSnapshotCallback) {
        window.advanceSnapshotRequested(readyForSnapshotCallback)
      });
    }

    await browser.deleteSession()
    process.exit()

})().catch((err) => {
    console.error(err)
    browser.deleteSession()
    process.exit()
})

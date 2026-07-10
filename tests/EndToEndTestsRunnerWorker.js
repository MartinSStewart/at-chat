const { parentPort } = require('node:worker_threads');
const xhr = require('./XMLHttpRequest.js');
const image = require('./Image.js');

global.XMLHttpRequest = xhr.XMLHttpRequest;
global.Image = image.Image;

const { Elm } = require('./EndToEndTestsRunnerElm.js');

const app = Elm.EndToEndTestsRunner.init();

app.ports.testsLoaded.subscribe(data => {
    parentPort.postMessage({ type: 'loaded', ...data });
});

app.ports.testResult.subscribe(result => {
    parentPort.postMessage({ type: 'result', ...result });
});

parentPort.on('message', testIndex => {
    app.ports.runTest.send(testIndex);
});

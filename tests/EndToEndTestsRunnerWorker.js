const { parentPort } = require('node:worker_threads');
const xhr = require('./XMLHttpRequest.js');
const image = require('./Image.js');

global.XMLHttpRequest = xhr.XMLHttpRequest;
global.Image = image.Image;

const { Elm } = require('./EndToEndTestsRunnerElm.js');

parentPort.on('message', moduleName => {
    const app = Elm[moduleName].init();
    // Port names have to be unique across the whole compiled bundle, so each
    // batch module suffixes its port with the batch number.
    const portName = 'testResults' + moduleName.replace('EndToEndTestsRunnerBatch', '');
    app.ports[portName].subscribe(results => {
        parentPort.postMessage({ moduleName, results });
    });
});

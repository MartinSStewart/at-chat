const { Elm } = require('./EndToEndTestsRunnerElm.js');
const xhr = require('./XMLHttpRequest.js');
const image = require('./Image.js');

global.XMLHttpRequest = xhr.XMLHttpRequest;
global.Image = image.Image;

const app = Elm.EndToEndTestsRunner.init();
app.ports.testResults.subscribe(results => {
    if (results) {
        console.error(results);
        process.exit(1);
    }
    else
    {
        console.log("All end-to-end tests passed!");
        process.exit();
    }
});

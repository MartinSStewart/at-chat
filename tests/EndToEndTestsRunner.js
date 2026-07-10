// Runs the end-to-end tests in parallel. Each worker thread (see
// EndToEndTestsRunnerWorker.js) hosts an instance of the EndToEndTestsRunner
// Elm program, which loads the test list via Effect.Test.getTestResults and
// runs one test per request. Tests are handed out to workers one at a time so
// the load stays balanced regardless of how long individual tests take.
const { Worker } = require('node:worker_threads');
const os = require('node:os');
const path = require('node:path');

// XMLHttpRequest.js resolves file paths relative to the tests directory.
process.chdir(__dirname);

const workerCount = os.availableParallelism ? os.availableParallelism() : os.cpus().length;
console.log(`Running end-to-end tests on ${workerCount} worker threads...`);

const startTime = Date.now();
let totalTests = null;
let nextTest = 0;
let finishedTests = 0;
const failures = [];

function finish() {
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    if (failures.length > 0) {
        console.error('The following tests failed:\n' + failures.join('\n'));
        process.exit(1);
    }
    else {
        console.log(`All ${totalTests} end-to-end tests passed! (${elapsed}s)`);
        process.exit();
    }
}

function runNextTest(worker) {
    if (nextTest < totalTests) {
        worker.postMessage(nextTest);
        nextTest++;
    }
    else {
        worker.terminate();
    }
}

for (let i = 0; i < workerCount; i++) {
    const worker = new Worker(path.join(__dirname, 'EndToEndTestsRunnerWorker.js'));

    worker.on('message', message => {
        if (message.type === 'loaded') {
            if (message.error !== undefined) {
                console.error(message.error);
                process.exit(1);
            }
            if (totalTests === null) {
                totalTests = message.testCount;
                if (totalTests === 0) {
                    finish();
                }
            }
            runNextTest(worker);
        }
        else if (message.type === 'result') {
            finishedTests++;
            if (message.error !== null) {
                console.log(`${message.name} failed`);
                failures.push(` - ${message.name}: ${message.error}`);
            }
            if (finishedTests === totalTests) {
                finish();
            }
            else {
                runNextTest(worker);
            }
        }
    });

    worker.on('error', error => {
        console.error(error);
        process.exit(1);
    });
}

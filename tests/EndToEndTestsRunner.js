// Runs the end-to-end tests in parallel. The Elm bundle contains one main per
// EndToEndTestsRunnerBatchN.elm module, each running a slice of the tests via
// Effect.Test.startHeadlessRange. Batches are distributed over a pool of
// worker threads (see EndToEndTestsRunnerWorker.js).
const { Worker } = require('node:worker_threads');
const os = require('node:os');
const path = require('node:path');

// XMLHttpRequest.js resolves file paths relative to the tests directory.
process.chdir(__dirname);

const { Elm } = require('./EndToEndTestsRunnerElm.js');

const batches = Object.keys(Elm)
    .filter(name => name.startsWith('EndToEndTestsRunnerBatch'))
    .sort((a, b) => Number(a.replace('EndToEndTestsRunnerBatch', '')) - Number(b.replace('EndToEndTestsRunnerBatch', '')));

if (batches.length === 0) {
    console.error('No EndToEndTestsRunnerBatch modules found in EndToEndTestsRunnerElm.js');
    process.exit(1);
}

const workerCount = Math.min(os.availableParallelism ? os.availableParallelism() : os.cpus().length, batches.length);
console.log(`Running ${batches.length} test batches on ${workerCount} worker threads...`);

const startTime = Date.now();
let nextBatch = 0;
let remainingBatches = batches.length;
const failures = [];

function runNextBatch(worker) {
    if (nextBatch < batches.length) {
        worker.batchStartTime = Date.now();
        worker.postMessage(batches[nextBatch]);
        nextBatch++;
    }
    else {
        worker.terminate();
    }
}

function batchFinished() {
    remainingBatches--;
    if (remainingBatches === 0) {
        const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
        if (failures.length > 0) {
            console.error(failures.join('\n'));
            process.exit(1);
        }
        else {
            console.log(`All end-to-end tests passed! (${elapsed}s)`);
            process.exit();
        }
    }
}

for (let i = 0; i < workerCount; i++) {
    const worker = new Worker(path.join(__dirname, 'EndToEndTestsRunnerWorker.js'));

    worker.on('message', ({ moduleName, results }) => {
        const elapsed = ((Date.now() - worker.batchStartTime) / 1000).toFixed(1);
        if (results === null) {
            console.log(`${moduleName} passed (${elapsed}s)`);
        }
        else if (results === 'No tests executed') {
            // This batch's range starts beyond the total number of tests.
            console.log(`${moduleName} had no tests to run`);
        }
        else {
            console.log(`${moduleName} failed (${elapsed}s)`);
            failures.push(results);
        }
        batchFinished();
        runNextBatch(worker);
    });

    worker.on('error', error => {
        console.error(error);
        process.exit(1);
    });

    runNextBatch(worker);
}

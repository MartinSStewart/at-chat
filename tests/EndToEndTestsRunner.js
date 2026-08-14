// Runs the end-to-end tests in parallel. Each worker thread (see
// EndToEndTestsRunnerWorker.js) hosts an instance of the EndToEndTestsRunner
// Elm program, which loads the test list via Effect.Test.getTestResults and
// runs one test per request. Tests are handed out to workers one at a time so
// the load stays balanced regardless of how long individual tests take.
const { Worker } = require('node:worker_threads');
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const projectRoot = path.join(__dirname, '..');
const compiledTests = path.join(__dirname, 'EndToEndTestsRunnerElm.js');

// The workers run compiled Elm, so without this the tests silently run against
// whatever was compiled last rather than against the source on disk. Compiling
// here rather than in the npm script means it happens however this file is
// started.
function compileTests() {
    // `lamdera` is often not on PATH, so prefer the one npm installed.
    const local = path.join(projectRoot, 'node_modules', '.bin', 'lamdera');
    const compiler = fs.existsSync(local) ? local : 'lamdera';
    console.log('Compiling the end-to-end tests...');
    try {
        execFileSync(
            compiler,
            ['make', 'tests/EndToEndTestsRunner.elm', '--output', compiledTests],
            { cwd: projectRoot, stdio: 'inherit' }
        );
    }
    catch (error) {
        console.error('Compiling the end-to-end tests failed. Not running them against a stale build.');
        process.exit(1);
    }
}

compileTests();

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

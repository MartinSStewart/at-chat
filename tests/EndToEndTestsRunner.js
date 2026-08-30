// Runs the end-to-end tests in parallel. Each worker thread (see
// EndToEndTestsRunnerWorker.js) hosts an instance of the EndToEndTestsRunner
// Elm program, which loads the test list via Effect.Test.getTestResults and
// runs one test per request. Tests are handed out to workers one at a time so
// the load stays balanced regardless of how long individual tests take.
//
// Usage:
//   node tests/EndToEndTestsRunner.js                 runs every test
//   node tests/EndToEndTestsRunner.js "part of name"  runs the one test that matches
//   node tests/EndToEndTestsRunner.js --list          prints the test names
const { Worker } = require('node:worker_threads');
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const projectRoot = path.join(__dirname, '..');
const compiledTests = path.join(__dirname, 'EndToEndTestsRunnerElm.js');

const args = process.argv.slice(2);
const listOnly = args.includes('--list');
const nameFilter = args.find(argument => !argument.startsWith('--'));

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

// An exact name wins over a partial one, so a test whose name is contained in
// another test's name can still be picked.
function testsMatching(filter, testNames) {
    const lowercase = filter.toLowerCase();
    const exact = testNames.findIndex(name => name.toLowerCase() === lowercase);
    if (exact !== -1) {
        return [exact];
    }
    const matches = [];
    testNames.forEach((name, index) => {
        if (name.toLowerCase().includes(lowercase)) {
            matches.push(index);
        }
    });
    return matches;
}

// The indices of the tests to run, or null when a message should be printed
// instead of running anything.
function selectTests(testNames) {
    if (listOnly) {
        console.log(testNames.map(name => ` - ${name}`).join('\n'));
        return null;
    }
    if (nameFilter === undefined) {
        return testNames.map((_, index) => index);
    }
    const matches = testsMatching(nameFilter, testNames);
    if (matches.length === 0) {
        console.error(
            `No end-to-end test matches "${nameFilter}". The tests are:\n`
            + testNames.map(name => ` - ${name}`).join('\n')
        );
        process.exit(1);
    }
    if (matches.length > 1) {
        console.error(
            `"${nameFilter}" matches several end-to-end tests. Pass more of the name to pick one:\n`
            + matches.map(index => ` - ${testNames[index]}`).join('\n')
        );
        process.exit(1);
    }
    return matches;
}

// There's nothing to parallelize when a single test was picked, and starting a
// worker is expensive because each one loads the whole test list.
const workerCount =
    nameFilter === undefined && !listOnly
        ? (os.availableParallelism ? os.availableParallelism() : os.cpus().length)
        : 1;

if (listOnly) {
    console.log('Loading the end-to-end tests...');
}
else if (nameFilter === undefined) {
    console.log(`Running end-to-end tests on ${workerCount} worker threads...`);
}
else {
    console.log(`Looking for an end-to-end test matching "${nameFilter}"...`);
}

const startTime = Date.now();
let remainingTests = null;
let totalTests = 0;
let finishedTests = 0;
const failures = [];

function finish() {
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    if (failures.length > 0) {
        console.error('The following tests failed:\n' + failures.join('\n'));
        process.exit(1);
    }
    else {
        console.log(`All ${totalTests} end-to-end test${totalTests === 1 ? '' : 's'} passed! (${elapsed}s)`);
        process.exit();
    }
}

function runNextTest(worker) {
    if (remainingTests.length > 0) {
        worker.postMessage(remainingTests.shift());
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
            if (remainingTests === null) {
                const selected = selectTests(message.testNames);
                if (selected === null) {
                    process.exit();
                }
                remainingTests = selected;
                totalTests = selected.length;
                if (nameFilter !== undefined) {
                    console.log(`Running ${message.testNames[selected[0]]}`);
                }
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

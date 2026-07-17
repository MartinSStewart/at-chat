#!/usr/bin/env node
// app-cli: a REPL for sending ToBackend messages directly to the at-chat backend.
//
// Usage: npm run app-cli   (requires `lamdera live` to be running, with at least
// one browser tab open on it — in lamdera live the backend runs in the leader tab)
//
// Type an Elm expression of type Types.ToBackend, e.g.
//
//     > CheckLoginRequest InitialLoadRequested_None
//
// The expression is pasted into a temporary Elm module which is compiled with
// `lamdera make`. The compiled Platform.worker encodes the message with the
// generated Types.w3_encode_ToBackend wire encoder, and this script sends the
// bytes to the backend over lamdera live's websocket (the same protocol the
// browser harness uses, see extra/live.js in the lamdera compiler). ToFrontend
// responses are decoded by the worker with Types.w3_decode_ToFrontend and
// printed via Debug.toString.

'use strict';

const fs = require('node:fs');
const path = require('node:path');
const readline = require('node:readline');
const crypto = require('node:crypto');
const { spawn } = require('node:child_process');

const repoRoot = path.resolve(__dirname, '..');
const workDir = path.join(repoRoot, 'elm-stuff', 'app-cli');
const srcCliDir = path.join(workDir, 'src-cli');
const workerElmPath = path.join(srcCliDir, 'AppCliWorker.elm');
const workerJsPath = path.join(workDir, 'AppCliWorker.js');
const warmupElmPath = path.join(srcCliDir, 'AppCliWarmup.elm');
const warmupJsPath = path.join(workDir, 'AppCliWarmup.js');
const sessionFile = path.join(workDir, 'session-id.txt');

const printLimit = 5000;

// ---------------------------------------------------------------------------
// Command line arguments

const args = process.argv.slice(2);
let url = 'ws://localhost:8000/_w';
let sessionIdArg = null;
let newSession = false;

for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
        case '--url':
            url = args[++i];
            break;
        case '--session':
            sessionIdArg = args[++i];
            break;
        case '--new-session':
            newSession = true;
            break;
        case '--help':
        case '-h':
            console.log(`app-cli: send ToBackend messages to a running \`lamdera live\` backend.

Options:
  --url <url>        Websocket url (default ws://localhost:8000/_w)
  --session <sid>    Use a specific session id. Copy the \`sid\` cookie from your
                     browser to act as that browser session (e.g. stay logged in).
  --new-session      Generate a fresh session id instead of reusing the stored one.
  --help             Show this help.

Type "help" inside the REPL for the available commands.`);
            process.exit(0);
        default:
            console.error(`Unknown argument: ${args[i]} (try --help)`);
            process.exit(1);
    }
}

// ---------------------------------------------------------------------------
// Work directory setup (lives inside elm-stuff so it is gitignored and not
// watched by lamdera live)

fs.mkdirSync(srcCliDir, { recursive: true });

const repoElmJson = JSON.parse(fs.readFileSync(path.join(repoRoot, 'elm.json'), 'utf8'));
const workElmJson = {
    ...repoElmJson,
    'source-directories': ['src-cli'].concat(
        repoElmJson['source-directories'].map(dir => '../../' + dir)
    ),
};
fs.writeFileSync(path.join(workDir, 'elm.json'), JSON.stringify(workElmJson, null, 4));

function getSessionId() {
    if (sessionIdArg !== null) {
        return sessionIdArg;
    }
    if (!newSession && fs.existsSync(sessionFile)) {
        return fs.readFileSync(sessionFile, 'utf8').trim();
    }
    // Same shape as the session ids lamdera live generates server side
    const sid = crypto.randomBytes(20).toString('hex');
    fs.writeFileSync(sessionFile, sid);
    return sid;
}

const sessionId = getSessionId();

function findLamdera() {
    const local = path.join(repoRoot, 'node_modules', '.bin', 'lamdera');
    return fs.existsSync(local) ? local : 'lamdera';
}

const lamderaBin = findLamdera();

// ---------------------------------------------------------------------------
// Elm module generation

// Modules in src/ that don't compile as part of the app (e.g. stale migration
// helpers referencing deleted Evergreen versions)
const excludedModules = new Set(['MigrateStuff', 'Main']);

// All app modules get imported qualified so that expressions can reference
// helpers like Id.fromString without any setup. Evergreen migration modules
// are skipped (huge and never needed for constructing a ToBackend value).
function defaultImports() {
    const imports = [];
    const srcDir = path.join(repoRoot, 'src');

    const walk = dir => {
        for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
            const full = path.join(dir, entry.name);
            if (entry.isDirectory()) {
                if (path.relative(srcDir, full) !== 'Evergreen') {
                    walk(full);
                }
            } else if (entry.name.endsWith('.elm')) {
                const moduleName = path
                    .relative(srcDir, full)
                    .slice(0, -'.elm'.length)
                    .split(path.sep)
                    .join('.');
                if (moduleName !== 'Types' && !excludedModules.has(moduleName)) {
                    imports.push(moduleName);
                }
            }
        }
    };
    walk(srcDir);

    // Vendored modules that ToBackend constructor arguments commonly need
    imports.push('Discord', 'EmailAddress');
    return imports;
}

const userImports = [];

function importLines() {
    const lines = new Set(['Types exposing (..)', 'Base64', 'Bytes.Decode', 'Bytes.Encode']);
    for (const moduleName of defaultImports()) {
        lines.add(moduleName);
    }
    for (const userImport of userImports) {
        lines.add(userImport);
    }
    return [...lines].map(line => 'import ' + line).join('\n');
}

function workerSource(expression) {
    return `port module AppCliWorker exposing (main)

${importLines()}


port appCliSendToBackend : String -> Cmd msg


port appCliWriteLine : String -> Cmd msg


port appCliReceiveToFrontend : (String -> msg) -> Sub msg


toBackendMsg : Types.ToBackend
toBackendMsg =
    (${expression})


type Msg
    = GotToFrontend String


main : Program () () Msg
main =
    Platform.worker
        { init =
            \\() ->
                ( ()
                , case Base64.fromBytes (Bytes.Encode.encode (Types.w3_encode_ToBackend toBackendMsg)) of
                    Just base64 ->
                        appCliSendToBackend base64

                    Nothing ->
                        appCliWriteLine "Error: failed to base64 encode the ToBackend message"
                )
        , update = update
        , subscriptions = \\_ -> appCliReceiveToFrontend GotToFrontend
        }


update : Msg -> () -> ( (), Cmd Msg )
update (GotToFrontend base64) () =
    ( ()
    , case Base64.toBytes base64 of
        Just bytes ->
            case Bytes.Decode.decode Types.w3_decode_ToFrontend bytes of
                Just toFrontend ->
                    appCliWriteLine (Debug.toString toFrontend)

                Nothing ->
                    appCliWriteLine "Error: could not decode ToFrontend message. Is the backend running the same Types.elm as this checkout?"

        Nothing ->
            appCliWriteLine "Error: failed to base64 decode ToFrontend message"
    )
`;
}

function warmupSource() {
    return `module AppCliWarmup exposing (main)

${importLines()}


main : Program () () ()
main =
    Platform.worker
        { init = \\() -> ( (), Cmd.none )
        , update = \\_ model -> ( model, Cmd.none )
        , subscriptions = \\_ -> Sub.none
        }
`;
}

// ---------------------------------------------------------------------------
// Compiling (serialized: two lamdera processes must not share elm-stuff)

let compileChain = Promise.resolve();

function compile(elmPath, jsPath) {
    const run = () =>
        new Promise(resolve => {
            const proc = spawn(lamderaBin, ['make', path.relative(workDir, elmPath), '--output=' + jsPath], {
                cwd: workDir,
            });
            let output = '';
            proc.stdout.on('data', data => (output += data));
            proc.stderr.on('data', data => (output += data));
            proc.on('error', error => resolve({ ok: false, output: String(error) }));
            proc.on('close', code => resolve({ ok: code === 0, output }));
        });
    const result = compileChain.then(run, run);
    compileChain = result;
    return result;
}

// ---------------------------------------------------------------------------
// Websocket connection (protocol from the lamdera compiler's extra/live.js)

let ws = null;
let clientId = null;
let leaderId = null;
let connected = false;
let closedByUs = false;
let warnedAboutLeader = false;
const outbound = [];

function connect() {
    let socket;
    try {
        // headers is a non-standard undici extension; passing the sid cookie
        // makes lamdera live associate this connection with our session id.
        socket = new WebSocket(url, { headers: { cookie: 'sid=' + sessionId } });
    } catch (error) {
        socket = new WebSocket(url);
    }
    ws = socket;

    socket.onmessage = event => {
        let data;
        try {
            data = JSON.parse(event.data);
        } catch (error) {
            return;
        }
        handleFrame(data);
    };
    socket.onclose = () => {
        const wasConnected = connected;
        connected = false;
        clientId = null;
        if (closedByUs) {
            return;
        }
        if (wasConnected) {
            printAbovePrompt(`Disconnected from ${url}, reconnecting...`);
        }
        setTimeout(connect, 2000);
    };
    socket.onerror = () => {};
}

function weAreLeader() {
    // In lamdera live the backend runs inside the leader browser tab. If this
    // CLI got elected leader then no tab is running the backend, so drop the
    // connection (which triggers a re-election) and retry until a browser tab
    // has taken over leadership.
    if (!warnedAboutLeader) {
        warnedAboutLeader = true;
        printAbovePrompt(
            'No browser tab is running the at-chat backend!\n' +
                `Open ${url.replace(/^ws/, 'http').replace(/\/_w$/, '/')} in a browser and keep the tab open.\n` +
                'Retrying every few seconds...'
        );
    }
    connected = false;
    clientId = null;
    closedByUs = true;
    ws.close();
    setTimeout(() => {
        closedByUs = false;
        connect();
    }, 3000);
}

function handleFrame(data) {
    switch (data.t) {
        case 's': // setup: the server tells us our client id and the leader
            clientId = data.c;
            leaderId = data.l;
            if (clientId === leaderId) {
                weAreLeader();
            } else {
                connected = true;
                if (warnedAboutLeader) {
                    warnedAboutLeader = false;
                    printAbovePrompt('Backend found.');
                }
                flushOutbound();
            }
            break;

        case 'e': // a new leader was elected
            leaderId = data.l;
            if (clientId !== null && clientId === leaderId) {
                weAreLeader();
            }
            break;

        case 'ToFrontend':
            if ((data.c === clientId || data.c === sessionId || data.c === 'b') && data.b && activeApp !== null) {
                activeApp.ports.appCliReceiveToFrontend.send(data.b);
            }
            break;

        default:
            // "c"/"d" (dis)connections, "p" backend state persistence, "r" reload,
            // "q" rpc, "x" noop, "ToBackend" relays: not relevant for the CLI
            break;
    }
}

function flushOutbound() {
    while (connected && outbound.length > 0) {
        const base64 = outbound.shift();
        ws.send(JSON.stringify({ t: 'ToBackend', s: sessionId, c: clientId, b: base64 }));
    }
}

function sendToBackend(base64) {
    outbound.push(base64);
    if (connected) {
        flushOutbound();
    } else {
        printAbovePrompt('Not connected yet, message queued.');
    }
}

// ---------------------------------------------------------------------------
// Worker instances

let activeApp = null;
let lastResponse = null;

function activateWorker() {
    delete require.cache[require.resolve(workerJsPath)];
    const { Elm } = require(workerJsPath);
    const app = Elm.AppCliWorker.init();
    activeApp = app;
    app.ports.appCliSendToBackend.subscribe(base64 => {
        if (app === activeApp) {
            sendToBackend(base64);
        }
    });
    app.ports.appCliWriteLine.subscribe(line => {
        if (app === activeApp) {
            printResponse(line);
        }
    });
}

function printResponse(text) {
    lastResponse = text;
    if (text.length > printLimit) {
        printAbovePrompt(
            text.slice(0, printLimit) + ` ...(${text.length - printLimit} more characters, type "last" to see everything)`
        );
    } else {
        printAbovePrompt(text);
    }
}

// ---------------------------------------------------------------------------
// REPL

const rl = readline.createInterface({ input: process.stdin, output: process.stdout, prompt: '> ' });

function printAbovePrompt(text) {
    readline.cursorTo(process.stdout, 0);
    readline.clearLine(process.stdout, 0);
    console.log(text);
    rl.prompt(true);
}

const helpText = `Type an Elm expression of type Types.ToBackend to send it to the backend, e.g.

    CheckLoginRequest InitialLoadRequested_None

Types is imported with exposing (..), every module in src/ is imported
qualified (Id, Pages.Admin, ...), and Discord/EmailAddress are also available.

Commands:
  import <module>    Add an import for later expressions, e.g. "import Dict exposing (empty)"
  unimport <module>  Remove a previously added import
  imports            List the imports added with the import command
  last               Reprint the last response without truncation
  session            Show the session id used for outgoing messages
  help               Show this help
  exit               Quit (also ctrl+d or ctrl+c)`;

let busy = false;

rl.on('line', line => {
    const input = line.trim();
    if (input === '') {
        rl.prompt();
    } else if (input === 'help') {
        console.log(helpText);
        rl.prompt();
    } else if (input === 'exit' || input === 'quit') {
        rl.close();
    } else if (input === 'imports') {
        console.log(userImports.length === 0 ? '(none)' : userImports.join('\n'));
        rl.prompt();
    } else if (input === 'last') {
        console.log(lastResponse === null ? '(no response received yet)' : lastResponse);
        rl.prompt();
    } else if (input === 'session') {
        console.log(sessionId);
        rl.prompt();
    } else if (input.startsWith('import ')) {
        userImports.push(input.slice('import '.length).trim());
        rl.prompt();
    } else if (input.startsWith('unimport ')) {
        const target = input.slice('unimport '.length).trim();
        const index = userImports.findIndex(imp => imp === target || imp.split(' ')[0] === target);
        if (index === -1) {
            console.log(`No user import matching "${target}"`);
        } else {
            userImports.splice(index, 1);
        }
        rl.prompt();
    } else if (busy) {
        console.log('Still compiling the previous message, try again in a moment.');
        rl.prompt();
    } else {
        sendExpression(input);
    }
});

rl.on('close', () => {
    closedByUs = true;
    if (ws !== null) {
        try {
            ws.close();
        } catch (error) {}
    }
    process.exit(0);
});

function sendExpression(expression) {
    busy = true;
    process.stdout.write('Compiling... ');
    fs.writeFileSync(workerElmPath, workerSource(expression));
    compile(workerElmPath, workerJsPath).then(result => {
        busy = false;
        if (result.ok) {
            console.log('sent. Responses are printed as they arrive.');
            activateWorker();
        } else {
            console.log('failed:\n');
            console.log(result.output.replace(/^Compiling \.\.\..*$\n?/m, ''));
        }
        rl.prompt();
    });
}

// ---------------------------------------------------------------------------
// Startup

console.log(`at-chat app-cli — session ${sessionId}`);
console.log(`Connecting to ${url} (make sure \`lamdera live\` is running and a browser tab is open).`);
console.log('Type "help" for usage. Warming up the compiler in the background...');

fs.writeFileSync(warmupElmPath, warmupSource());
compile(warmupElmPath, warmupJsPath).then(result => {
    if (result.ok) {
        printAbovePrompt('Compiler warmed up, messages will now compile quickly.');
    } else {
        printAbovePrompt('Warmup compile failed:\n' + result.output);
    }
});

connect();
rl.prompt();

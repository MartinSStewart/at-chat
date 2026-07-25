// Starts the Backup.elm worker and implements the ports it uses to reach the
// outside world.
//
// Backup.elm used to be an Eco program, which let it call Eco.File, Eco.Process
// and Eco.Console directly. Eco can't compile Lamdera projects, and the backup
// integrity check needs the w3_decode functions the Lamdera compiler generates,
// so the program is compiled with `lamdera make` and this file provides the
// handful of capabilities Eco used to.
//
// Build and run it with `npm run backup-downloader` from the repo root.
//
// Every request from Elm is a JSON object with a `tag` field. Requests that
// expect an answer are replied to on the fromJs port with the same tag. Only one
// request is ever in flight.

const fs = require('node:fs');
const path = require('node:path');
const { spawn } = require('node:child_process');

const { Elm } = require('./BackupElm.js');

// Resolved up front so that every path the program prints is absolute. A
// relative path is only meaningful next to the working directory it was run
// from, which makes "where did my reference exports go?" needlessly hard to
// answer — especially since at-chat-backups/ is gitignored and editors like to
// hide ignored folders.
const dest = path.resolve(process.env.AT_CHAT_BACKUP_DEST || './at-chat-backups');

const app = Elm.Backup.init({
    flags: {
        source: process.env.AT_CHAT_BACKUP_SOURCE || 'root@at-chat.app:/var/lib/atchat/backups/',
        dest: dest,
        // Reference exports live next to the backups so that a single folder holds
        // everything this program produces.
        referenceDir: path.join(dest, 'reference-exports'),
        sshKey: process.env.AT_CHAT_SSH_KEY || null,
        time: Date.now(),
        // A fresh seed each run means a different random subset of channels gets
        // checked, so coverage builds up over time.
        seed: (Math.random() * 0x7fffffff) | 0
    }
});

function reply(message) {
    // Deliver asynchronously so Elm has finished processing the current message
    // before the answer arrives.
    setTimeout(() => app.ports.fromJs.send(message), 0);
}

function errorMessage(error) {
    return error && error.message ? error.message : String(error);
}

/** Look for an executable on PATH the way `Eco.File.findExecutable` did. */
function findExecutable(name) {
    const extensions = process.platform === 'win32' ? (process.env.PATHEXT || '.EXE').split(path.delimiter) : [''];
    return (process.env.PATH || '').split(path.delimiter).some(dir =>
        dir !== '' && extensions.some(extension => {
            try {
                fs.accessSync(path.join(dir, name + extension), fs.constants.X_OK);
                return true;
            }
            catch {
                return false;
            }
        })
    );
}

const handlers = {
    stdout(request) {
        process.stdout.write(request.text + '\n');
    },

    stderr(request) {
        process.stderr.write(request.text + '\n');
    },

    exit(request) {
        // Setting exitCode rather than calling process.exit() lets any buffered
        // stdout finish writing. Node exits on its own once nothing is pending.
        process.exitCode = request.code;
    },

    findExecutable(request) {
        reply({ tag: 'findExecutable', found: findExecutable(request.name) });
    },

    dirExists(request) {
        let exists;
        try {
            exists = fs.statSync(request.path).isDirectory();
        }
        catch {
            exists = false;
        }
        reply({ tag: 'dirExists', exists: exists });
    },

    createDir(request) {
        try {
            fs.mkdirSync(request.path, { recursive: true });
            reply({ tag: 'createDir', error: null });
        }
        catch (error) {
            reply({ tag: 'createDir', error: errorMessage(error) });
        }
    },

    // Replaces Eco.Process.spawn followed by Eco.Process.wait. The program only
    // ever runs one process at a time, so there's no need to hand a handle back
    // to Elm and wait on it separately.
    runProcess(request) {
        let child;
        try {
            child = spawn(request.command, request.args, { stdio: ['ignore', 'inherit', 'inherit'] });
        }
        catch (error) {
            reply({ tag: 'runProcess', exitCode: 1, error: errorMessage(error) });
            return;
        }
        child.on('error', error => reply({ tag: 'runProcess', exitCode: 1, error: errorMessage(error) }));
        child.on('close', code => reply({ tag: 'runProcess', exitCode: code === null ? 1 : code, error: null }));
    },

    listDir(request) {
        try {
            reply({ tag: 'listDir', files: fs.readdirSync(request.path), error: null });
        }
        catch (error) {
            reply({ tag: 'listDir', files: [], error: errorMessage(error) });
        }
    },

    readFile(request) {
        reply({ tag: 'readFile', contents: readFile(request.path, 'utf8') });
    },

    // Lamdera lets Bytes cross a port as a DataView, so a backup goes into Elm
    // without being copied or re-encoded. Handing it over as base64 instead
    // turned a 21 MB backup into 2.3 GB of intermediate encoders on the Elm side.
    // A successful read answers on the bytes port and a failed one on the normal
    // port, so exactly one of the two arrives.
    readBackupFile(request) {
        let buffer;
        try {
            buffer = fs.readFileSync(request.path);
        }
        catch (error) {
            reply({ tag: 'readBackupFile', error: errorMessage(error) });
            return;
        }
        setTimeout(() => app.ports.backupFileFromJs.send(new DataView(toArrayBuffer(buffer))), 0);
    },

    writeFile(request) {
        try {
            fs.mkdirSync(path.dirname(request.path), { recursive: true });
            fs.writeFileSync(request.path, request.contents);
            reply({ tag: 'writeFile', error: null });
        }
        catch (error) {
            reply({ tag: 'writeFile', error: errorMessage(error) });
        }
    }
};

/** Small reads share a pooled buffer, so those have to be copied out of it. */
function toArrayBuffer(buffer) {
    return buffer.byteOffset === 0 && buffer.byteLength === buffer.buffer.byteLength
        ? buffer.buffer
        : buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength);
}

/** `null` means the file isn't there, which Elm treats as "no reference export yet". */
function readFile(filePath, encoding) {
    try {
        return fs.readFileSync(filePath, encoding);
    }
    catch {
        return null;
    }
}

app.ports.toJs.subscribe(request => {
    const handler = handlers[request.tag];
    if (handler === undefined) {
        process.stderr.write(`Backup.elm asked for "${request.tag}" but run.js has no handler for it\n`);
        process.exitCode = 1;
        return;
    }
    handler(request);
});

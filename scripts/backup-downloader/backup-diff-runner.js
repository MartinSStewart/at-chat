// build-backup-diff.sh appends this to the compiled BackupDiff.elm, so that the result is a
// single file that can be copied to wherever the exports are and run with plain node:
//
//     node backup-diff.js <older export> <newer export>
//
// The exports are read one at a time and the first one's buffer is dropped before the second
// is read, so only one export is ever in memory along with the first one's summary.

const fs = require('node:fs');
const path = require('node:path');

const [oldPath, newPath] = process.argv.slice(2);

if (oldPath === undefined || newPath === undefined) {
    process.stderr.write('Usage: node backup-diff.js <older backend-export .bin> <newer backend-export .bin>\n');
    process.exit(2);
}

// The compiled Elm above this registers itself on `this`, which is module.exports in a
// CommonJS file.
const app = module.exports.Elm.BackupDiff.init({
    flags: { oldName: path.basename(oldPath), newName: path.basename(newPath) }
});

function toArrayBuffer(buffer) {
    return buffer.byteOffset === 0 && buffer.byteLength === buffer.buffer.byteLength
        ? buffer.buffer
        : buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength);
}

const startedAt = Date.now();

app.ports.toJs.subscribe(request => {
    if (request.tag === 'readFile') {
        const filePath = request.which === 'old' ? oldPath : newPath;
        process.stderr.write(`Decoding ${filePath}...\n`);
        let buffer;
        try {
            buffer = fs.readFileSync(filePath);
        }
        catch (error) {
            process.stderr.write(`Couldn't read ${filePath}: ${error.message}\n`);
            process.exit(1);
        }
        // Sent asynchronously so Elm has finished handling the request first.
        setTimeout(() => app.ports.fileFromJs.send(new DataView(toArrayBuffer(buffer))), 0);
    }
    else if (request.tag === 'finish') {
        const seconds = ((Date.now() - startedAt) / 1000).toFixed(1);
        const peakMb = Math.round(process.resourceUsage().maxRSS / 1024);
        process.stdout.write(request.text + '\n');
        process.stderr.write(`Done in ${seconds}s, peak memory ${peakMb} MB.\n`);
        process.exitCode = request.succeeded ? 0 : 1;
    }
});

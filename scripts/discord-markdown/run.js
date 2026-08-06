// Runs DiscordMarkdownHarness.elm over a list of inputs and prints what happens to each
// one on its way to Discord and back.
//
// Build and run it with `npm run discord-markdown` from the repo root. Inputs come from
// the command line, from a file (`--file cases.txt`, one case per line), or from the
// default list below when neither is given.
//
// The "Discord shows" column needs a JavaScript port of Discord's markdown renderer:
//
//     npm install --no-save discord-markdown
//
// Without it the column is left out. The port is a community reimplementation rather than
// the real client, so treat it as a strong hint and not as proof — the cases that matter
// are worth pasting into a real Discord channel once.

const { Elm } = require('./DiscordMarkdownHarnessElm.js');
const fs = require('node:fs');

// Cases that the escaping rules keep getting wrong, plus the plain ones that must not
// regress. Anything given on the command line replaces them.
const defaultInputs = [
    '_',
    '__',
    '___',
    '*',
    '**',
    '~',
    '~~',
    '`',
    '||',
    '_italic_',
    '*bold*',
    '__underline__',
    '~~strike~~',
    '`code`',
    'snake_case_name',
    'a_b',
    '5 * 3 and 2 * 2',
    'a ` b',
    '`code` and a ` here',
    'a@b.com',
    '@everyone hi',
    '2 > 1',
    'back\\slash',
    '\\_',
    '\\*',
    '¯\\_(ツ)_/¯',
    'C:\\Users\\me',
    'a *b* c_d',
];

function parseArgs(argv) {
    const fileFlag = argv.indexOf('--file');

    if (fileFlag !== -1) {
        const path = argv[fileFlag + 1];

        if (path === undefined) {
            console.error('--file needs a path to a file with one case per line');
            process.exit(1);
        }

        return fs
            .readFileSync(path, 'utf8')
            .split('\n')
            .filter((line) => line !== '');
    }

    return argv.length > 0 ? argv : defaultInputs;
}

// The renderer port is optional so that the harness still runs without it.
function loadDiscordRenderer() {
    try {
        const { toHTML } = require('discord-markdown');
        return (text) => toHTML(text);
    } catch (error) {
        return null;
    }
}

// What a reader ends up seeing, with the markup tags turned back into something readable
// so that a visible backslash stands out in a terminal.
function renderedText(html) {
    return html
        .replace(/<em>(.*?)<\/em>/gs, '«i»$1«/i»')
        .replace(/<strong>(.*?)<\/strong>/gs, '«b»$1«/b»')
        .replace(/<u>(.*?)<\/u>/gs, '«u»$1«/u»')
        .replace(/<s>(.*?)<\/s>/gs, '«s»$1«/s»')
        .replace(/<code>(.*?)<\/code>/gs, '«code»$1«/code»')
        .replace(/<span class="d-spoiler">(.*?)<\/span>/gs, '«spoiler»$1«/spoiler»')
        .replace(/<br>/g, '\\n')
        .replace(/<[^>]*>/g, '')
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'");
}

const argv = process.argv.slice(2);
// --discord reads the cases as Discord message content instead of as text typed into
// at-chat, which is how to ask what at-chat believes Discord's own markdown means.
const asDiscordContent = argv.includes('--discord');
const inputs = parseArgs(argv.filter((arg) => arg !== '--discord'));
const render = loadDiscordRenderer();

const app = Elm.DiscordMarkdownHarness.init({
    flags: { inputs: inputs, asDiscordContent: asDiscordContent },
});

app.ports.output.subscribe((rows) => {
    const table = rows.map((row) => {
        const line = asDiscordContent
            ? { 'Discord content': row.typed, 'at-chat shows': row.comesBackAs }
            : { 'typed in at-chat': row.typed, 'sent to Discord': row.sentToDiscord };

        if (render !== null) {
            line['Discord shows'] = renderedText(
                render(asDiscordContent ? row.typed : row.sentToDiscord)
            );
        }

        if (!asDiscordContent) {
            line['round trips'] = row.survivesTheRoundTrip ? 'yes' : 'NO';
        }

        return line;
    });

    console.table(table);

    const broken = rows.filter((row) => !row.survivesTheRoundTrip);

    if (broken.length > 0) {
        console.log(
            '\nat-chat reads these differently after they have been to Discord and back:\n'
        );

        for (const row of broken) {
            console.log('  typed:     ' + JSON.stringify(row.typed));
            console.log('  at-chat:   ' + row.atChatReads);
            console.log('  sent:      ' + JSON.stringify(row.sentToDiscord));
            console.log('  came back: ' + row.comesBackAs);
            console.log('');
        }
    }

    if (render === null) {
        console.log(
            '\n(install discord-markdown for a "Discord shows" column: npm install --no-save discord-markdown)'
        );
    }

    process.exit(broken.length > 0 ? 1 : 0);
});

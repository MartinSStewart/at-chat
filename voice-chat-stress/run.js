#!/usr/bin/env node
// Puts a number of bots in one at-chat voice call, across Chromium, Firefox and
// WebKit, keeps them there for a while and reports what each of them received.
// See README.md for how to run it.

const fs = require("fs");
const os = require("os");
const path = require("path");
const playwright = require("playwright");

const instrumentSource = fs.readFileSync(path.join(__dirname, "instrument.js"), "utf8");

function parseArgs(argv) {
    const args = {
        command: "run",
        target: "http://localhost:8000",
        users: 8,
        browsers: ["chromium", "firefox", "webkit"],
        duration: 60,
        warmup: 15,
        video: true,
        headed: false,
        channelUrl: null,
        bots: null,
        out: path.join(__dirname, "results", new Date().toISOString().replace(/[:.]/g, "-")),
        name: null,
    };
    const rest = argv.slice(2);
    if (rest[0] === "login") {
        args.command = "login";
        rest.shift();
    }
    for (let i = 0; i < rest.length; i++) {
        const flag = rest[i];
        const value = () => {
            i += 1;
            if (rest[i] === undefined) throw new Error(flag + " needs a value");
            return rest[i];
        };
        if (flag === "--target") args.target = value().replace(/\/$/, "");
        else if (flag === "--users") args.users = parseInt(value(), 10);
        else if (flag === "--browsers") args.browsers = value().split(",");
        else if (flag === "--duration") args.duration = parseInt(value(), 10);
        else if (flag === "--warmup") args.warmup = parseInt(value(), 10);
        else if (flag === "--no-video") args.video = false;
        else if (flag === "--headed") args.headed = true;
        else if (flag === "--channel-url") args.channelUrl = value();
        else if (flag === "--bots") args.bots = value().split(",");
        else if (flag === "--out") args.out = path.resolve(value());
        else if (flag === "--name") args.name = value();
        else if (flag === "--profile") args.profile = true;
        else if (flag === "--use-saved-logins") args.useSavedLogins = true;
        else throw new Error("Unknown flag " + flag);
    }
    return args;
}

const isLocal = (target) => /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(target);

// --- launching browsers ---
//
// Chromium and Firefox have fake capture devices of their own, which go
// through the real getUserMedia path. WebKit has none, so instrument.js stands
// in a canvas and a tone for it (fakeMedia below).

const launched = {};

async function browserFor(name, args) {
    if (launched[name]) return launched[name];
    const headless = !args.headed;
    let browser;
    if (name === "chromium") {
        browser = await playwright.chromium.launch({
            headless,
            executablePath: process.env.CHROMIUM_PATH || undefined,
            args: [
                "--use-fake-ui-for-media-stream",
                "--use-fake-device-for-media-stream",
                "--autoplay-policy=no-user-gesture-required",
            ],
        });
    } else if (name === "firefox") {
        browser = await playwright.firefox.launch({
            headless,
            firefoxUserPrefs: {
                "media.navigator.streams.fake": true,
                "media.navigator.permission.disabled": true,
                "media.autoplay.default": 0,
                "media.autoplay.block-webaudio": false,
            },
        });
    } else if (name === "webkit") {
        browser = await playwright.webkit.launch({ headless });
    } else {
        throw new Error("Unknown browser " + name);
    }
    launched[name] = browser;
    return browser;
}

async function newBotPage(browserName, index, args, storageState) {
    const browser = await browserFor(browserName, args);
    const context = await browser.newContext({
        viewport: { width: 1280, height: 800 },
        storageState: storageState || undefined,
        permissions: browserName === "chromium" ? ["microphone", "camera", "clipboard-read", "clipboard-write"] : [],
    });
    const label = "bot" + index + " " + browserName;
    await context.addInitScript(
        "(" +
            instrumentSource.trim().replace(/;$/, "") +
            ")(" +
            JSON.stringify({
                fakeMedia: browserName === "webkit",
                noVideo: !args.video,
                // Spread over an octave and a half so no two bots share a pitch.
                toneHz: 220 * Math.pow(2, index / 6),
                hue: (index * 360) / 9,
                label: "bot" + index,
            }) +
            ");"
    );
    const page = await context.newPage();
    page.on("pageerror", (error) => log(label, "page error: " + error.message));
    page.on("console", (message) => {
        if (message.type() === "error" || (process.env.STRESS_DEBUG && /Call|Media|media|call/.test(message.text()))) {
            log(label, "console " + message.type() + ": " + message.text().slice(0, 300));
        }
    });
    return { browserName, index, label, context, page };
}

function log(...parts) {
    const time = new Date().toISOString().slice(11, 19);
    console.log(time, ...parts);
}

// --- signing up locally ---
//
// Under `lamdera live` the backend's Debug.log calls reach the console of the
// browser tab running the backend, which is how the login code is read. Every
// page's console is listened to, since which tab runs the backend is
// lamdera live's choice.

const loginCodes = [];
const loginCodeWaiters = [];

function listenForLoginCodes(page) {
    page.on("console", (message) => {
        const match = /^login: "?(\d+)/.exec(message.text());
        if (!match) return;
        const waiter = loginCodeWaiters.shift();
        if (waiter) waiter(match[1]);
        else loginCodes.push(match[1]);
    });
}

function nextLoginCode() {
    if (loginCodes.length > 0) return Promise.resolve(loginCodes.shift());
    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error("No login code arrived")), 20000);
        loginCodeWaiters.push((code) => {
            clearTimeout(timer);
            resolve(code);
        });
    });
}

async function enterEmailAndCode(page, email) {
    await page.fill("#loginForm_emailInput", email);
    loginCodes.length = 0;
    const code = nextLoginCode();
    await page.click("#loginForm_loginButton");
    await page.fill("#loginForm_loginCodeInput", await code);
}

async function signUpLocally(args, bots) {
    const [admin, ...others] = bots;

    log(admin.label, "logging in as the admin");
    await admin.page.goto(args.target + "/");
    await admin.page.click("#homePage_loginButton");
    await enterEmailAndCode(admin.page, "a@a.aa");

    // A fresh backend starts with one guild, which everyone joins.
    await admin.page.click("#guild_openGuild_0");
    await admin.page.click("#guild_inviteLinkCreatorRoute");
    await admin.page.click("#guild_createInviteLink");
    // The copy box is a read only text input holding the link.
    const inviteHandle = await admin.page.waitForFunction(
        (target) =>
            Array.from(document.querySelectorAll("input"))
                .map((input) => input.value)
                .find((value) => value.startsWith(target)),
        args.target
    );
    const inviteUrl = await inviteHandle.jsonValue();
    log("invite link", inviteUrl);

    // One at a time, since the login code can only be matched to whoever asked
    // for it last.
    for (const bot of others) {
        log(bot.label, "signing up");
        await bot.page.goto(inviteUrl);
        await enterEmailAndCode(bot.page, "stress-bot-" + bot.index + "@example.com");
        // lamdera live keeps its backend between runs, so a bot from an earlier
        // run already has an account and goes straight in.
        const isNew = await Promise.race([
            bot.page.waitForSelector("#loginForm_name").then(() => true),
            bot.page.waitForSelector("#guild_openChannel_0").then(() => false),
        ]);
        if (isNew) {
            await bot.page.fill("#loginForm_name", "Bot " + bot.index + " " + bot.browserName);
            await bot.page.click("#loginForm_submit");
        }
    }

    // By URL rather than by clicking the first channel, because the admin
    // starts on whichever channel it last viewed, and its channel list can be
    // in a different order from everyone else's.
    const channelUrl = args.channelUrl || args.target + "/g/0/c/0";
    for (const bot of bots) {
        await bot.page.goto(channelUrl);
    }
}

// --- production ---
//
// Bots there can't sign themselves up, because their login codes go out by
// email. Instead each one is logged in once by hand with `run.js login`, which
// saves its cookies, and every later run reuses them.

const loginsDir = path.join(__dirname, "logins");

async function loginCommand(args) {
    if (!args.name) throw new Error("login needs --name <bot name>, e.g. --name bot1");
    const browser = await playwright.chromium.launch({
        headless: false,
        executablePath: process.env.CHROMIUM_PATH || undefined,
    });
    const context = await browser.newContext();
    const page = await context.newPage();
    await page.goto(args.target + "/");
    console.log(
        "Log in as " +
            args.name +
            " in the window that opened, and join the guild the call will be in. Then press enter here."
    );
    await new Promise((resolve) => process.stdin.once("data", resolve));
    fs.mkdirSync(loginsDir, { recursive: true });
    const file = path.join(loginsDir, args.name + ".json");
    await context.storageState({ path: file });
    console.log("Saved " + file);
    await browser.close();
    process.exit(0);
}

function savedLogins(args) {
    const saved = (fs.existsSync(loginsDir) ? fs.readdirSync(loginsDir) : [])
        .filter((file) => file.endsWith(".json"))
        .map((file) => file.slice(0, -5))
        .sort();
    const names = args.bots || saved;
    if (names.length === 0) {
        throw new Error("No saved logins in " + loginsDir + ". Make some with `node run.js login --name bot1 --target " + args.target + "`.");
    }
    return names.slice(0, args.users).map((name) => JSON.parse(fs.readFileSync(path.join(loginsDir, name + ".json"), "utf8")));
}

// --- the call ---

async function joinCall(bot, args) {
    try {
        await bot.page.click("#guild_voiceChat");
        await bot.page.click("#guild_startVoiceChat");
        await bot.page.waitForFunction(() => window.__stress && window.__stress.roomUrl, null, { timeout: 20000 });
    } catch (error) {
        const screenshot = path.join(args.out, bot.label.replace(/ /g, "-") + "-failed-to-join.png");
        await bot.page.screenshot({ path: screenshot });
        throw new Error(bot.label + " couldn't join the call, see " + screenshot + "\n" + error.message);
    }
}

// CPU use of the whole machine between two readings of /proc/stat. Falls back
// to the load average where there is no /proc (macOS).
function cpuTimes() {
    const cpus = os.cpus();
    let idle = 0;
    let total = 0;
    for (const cpu of cpus) {
        idle += cpu.times.idle;
        total += cpu.times.user + cpu.times.nice + cpu.times.sys + cpu.times.irq + cpu.times.idle;
    }
    return { idle, total };
}

function percentile(values, p) {
    if (values.length === 0) return 0;
    const sorted = values.slice().sort((a, b) => a - b);
    return sorted[Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length))];
}

async function collect(bots) {
    return Promise.all(
        bots.map(async (bot) => {
            const stats = await bot.page.evaluate(() => {
                const s = window.__stress;
                return {
                    elapsedMs: performance.now() - s.startedAt,
                    received: s.received,
                    sent: s.sent,
                    decoded: s.decoded,
                    maxQueue: s.maxQueue,
                    socketMaxBuffered: s.socketMaxBuffered,
                    socketCloses: s.socketCloses,
                    lagSamples: s.lagSamples,
                    errors: s.errors,
                    roomUrl: s.roomUrl,
                    audioContexts: s.audioContextStates(),
                };
            });
            const errorBox = await bot.page
                .locator("#voiceChat_errorBox")
                .first()
                .textContent({ timeout: 500 })
                .catch(() => null);
            return { bot, stats, errorBox };
        })
    );
}

function pad(text, width) {
    text = String(text);
    return text.length >= width ? text : text + " ".repeat(width - text.length);
}

function summarise(results, args, cpuPercent) {
    const lines = [];
    const peers = results.length - 1;
    lines.push(
        "Voice chat stress test: " +
            results.length +
            " bots, " +
            (args.video ? "camera on" : "camera off") +
            ", " +
            args.duration +
            "s measured after " +
            args.warmup +
            "s warm-up, target " +
            args.target
    );
    lines.push("Machine: " + os.cpus().length + " cores, CPU busy " + cpuPercent.toFixed(0) + "% while measuring");
    lines.push("");
    lines.push(
        "Expected per listener: " +
            peers +
            " senders x 50 audio packets/s" +
            (args.video ? " and ~30 video frames/s" : "")
    );
    lines.push("");

    const header = [
        pad("bot", 18),
        pad("sent a/v per s", 15),
        pad("recv audio/s per sender (min-max)", 34),
        pad("recv video/s", 13),
        pad("worst audio gap", 16),
        pad("gaps>100ms", 11),
        pad("decoded a/v per s", 18),
        pad("dec err", 8),
        pad("main lag p95/max", 17),
        "notes",
    ];
    lines.push(header.join(""));

    for (const { bot, stats, errorBox } of results) {
        const seconds = stats.elapsedMs / 1000;
        const senders = Object.values(stats.received);
        const audioRates = senders.map((s) => s.audio / seconds);
        const videoRates = senders.map((s) => s.video / seconds);
        const worstGap = Math.max(0, ...senders.map((s) => s.maxAudioGapMs));
        const gaps = senders.reduce((sum, s) => sum + s.audioGapsOver100ms, 0);
        const notes = [];
        if (senders.length !== peers) notes.push("hears " + senders.length + "/" + peers + " senders");
        const suspended = stats.audioContexts.filter((state) => !state.startsWith("running"));
        if (suspended.length > 0) notes.push("audio context " + suspended.join(", "));
        if (stats.socketCloses.length > 0) notes.push("socket closed " + stats.socketCloses.join(","));
        if (errorBox) notes.push("error: " + errorBox.trim().slice(0, 80));
        if (stats.errors.length > 0) notes.push(stats.errors.slice(0, 2).join("; ").slice(0, 80));
        lines.push(
            [
                pad(bot.label, 18),
                pad((stats.sent.audio / seconds).toFixed(0) + "/" + (stats.sent.video / seconds).toFixed(0), 15),
                pad(
                    senders.length === 0
                        ? "-"
                        : Math.min(...audioRates).toFixed(1) + "-" + Math.max(...audioRates).toFixed(1),
                    34
                ),
                pad(
                    senders.length === 0
                        ? "-"
                        : Math.min(...videoRates).toFixed(0) + "-" + Math.max(...videoRates).toFixed(0),
                    13
                ),
                pad(worstGap.toFixed(0) + "ms", 16),
                pad(gaps, 11),
                pad((stats.decoded.audio / seconds).toFixed(0) + "/" + (stats.decoded.video / seconds).toFixed(0), 18),
                pad(stats.decoded.audioErrors + stats.decoded.videoErrors, 8),
                pad(percentile(stats.lagSamples, 95).toFixed(0) + "/" + Math.max(0, ...stats.lagSamples).toFixed(0) + "ms", 17),
                notes.join("; "),
            ].join("")
        );
    }
    lines.push("");
    lines.push(
        "decoded a/v per s is everything this bot's decoders produced across all senders, so with everyone " +
            "hearing everyone it should be about " +
            peers * 50 +
            "/" +
            (args.video ? peers * 30 : 0) +
            ". main lag is how late a 100ms timer fired on the bot's main thread; past ~50ms the bot itself is overloaded."
    );
    return lines.join("\n");
}

// --- profiling ---
//
// Where one Chromium bot's main thread spends its time during the call, which
// tells at-chat's own cost (Elm redraws, decoding, playback) apart from the
// harness's. Only Chromium exposes a CPU profiler to Playwright.

async function startProfiling(bots) {
    const bot = bots.find((candidate) => candidate.browserName === "chromium");
    if (!bot) {
        log("--profile needs a Chromium bot");
        return null;
    }
    const session = await bot.context.newCDPSession(bot.page);
    await session.send("Profiler.enable");
    await session.send("Profiler.setSamplingInterval", { interval: 1000 });
    await session.send("Profiler.start");
    return { bot, session };
}

async function stopProfiling({ bot, session }, args) {
    const { profile } = await session.send("Profiler.stop");
    fs.writeFileSync(path.join(args.out, bot.label.replace(/ /g, "-") + ".cpuprofile"), JSON.stringify(profile));

    const byId = new Map(profile.nodes.map((node) => [node.id, node]));
    const selfMs = new Map();
    for (let i = 0; i < profile.samples.length; i++) {
        const node = byId.get(profile.samples[i]);
        const frame = node.callFrame;
        const file = frame.url ? frame.url.split("/").pop().split("?")[0] : "";
        const key = (frame.functionName || "(anonymous)") + (file ? " " + file + ":" + (frame.lineNumber + 1) : "");
        selfMs.set(key, (selfMs.get(key) || 0) + profile.timeDeltas[i] / 1000);
    }
    const total = [...selfMs.values()].reduce((sum, ms) => sum + ms, 0);
    const busy = [...selfMs.entries()].filter(([key]) => key !== "(idle)" && key !== "(program)").reduce((sum, [, ms]) => sum + ms, 0);
    const lines = [
        "Main thread profile of " + bot.label + ": busy " + ((100 * busy) / total).toFixed(0) + "% of the time. Top functions by self time:",
    ];
    [...selfMs.entries()]
        .sort((a, b) => b[1] - a[1])
        .slice(0, 20)
        .forEach(([key, ms]) => lines.push("  " + pad(((100 * ms) / total).toFixed(1) + "%", 8) + key));
    return lines.join("\n");
}

async function run(args) {
    fs.mkdirSync(args.out, { recursive: true });
    const local = isLocal(args.target) && !args.useSavedLogins;

    let bots = [];
    if (local) {
        // An idle tab of its own for lamdera live's backend, so the backend
        // isn't competing with a bot's encoders for that tab's main thread.
        const host = await newBotPage("chromium", 0, args, null);
        host.label = "backend host";
        listenForLoginCodes(host.page);
        await host.page.goto(args.target + "/");

        for (let i = 1; i <= args.users; i++) {
            const bot = await newBotPage(args.browsers[(i - 1) % args.browsers.length], i, args, null);
            listenForLoginCodes(bot.page);
            bots.push(bot);
        }
        await signUpLocally(args, bots);
    } else {
        if (!args.channelUrl) throw new Error("--channel-url is needed with saved logins");
        const logins = savedLogins(args);
        for (let i = 0; i < logins.length; i++) {
            const bot = await newBotPage(args.browsers[i % args.browsers.length], i + 1, args, logins[i]);
            await bot.page.goto(args.channelUrl);
            bots.push(bot);
        }
    }

    for (const bot of bots) {
        log(bot.label, "joining the call");
        await joinCall(bot, args);
    }

    log("everyone has joined, warming up for " + args.warmup + "s");
    await new Promise((resolve) => setTimeout(resolve, args.warmup * 1000));
    await Promise.all(bots.map((bot) => bot.page.evaluate(() => window.__stress.reset())));
    const cpuBefore = cpuTimes();

    log("measuring for " + args.duration + "s");
    const profiler = args.profile ? await startProfiling(bots) : null;
    await new Promise((resolve) => setTimeout(resolve, args.duration * 1000));
    const profile = profiler ? await stopProfiling(profiler, args) : null;
    const cpuAfter = cpuTimes();
    const cpuPercent = 100 * (1 - (cpuAfter.idle - cpuBefore.idle) / (cpuAfter.total - cpuBefore.total));

    const results = await collect(bots);
    const summary = summarise(results, args, cpuPercent);
    console.log("\n" + summary + "\n");
    if (profile) console.log(profile + "\n");

    fs.writeFileSync(path.join(args.out, "summary.txt"), summary + "\n" + (profile ? "\n" + profile + "\n" : ""));
    fs.writeFileSync(
        path.join(args.out, "stats.json"),
        JSON.stringify(
            results.map(({ bot, stats, errorBox }) => ({ bot: bot.label, errorBox, ...stats })),
            null,
            2
        )
    );
    for (const bot of bots) {
        await bot.page.screenshot({ path: path.join(args.out, bot.label.replace(/ /g, "-") + ".png") });
    }
    log("results in " + args.out);

    for (const browser of Object.values(launched)) await browser.close();
}

const args = parseArgs(process.argv);
(args.command === "login" ? loginCommand(args) : run(args)).catch(async (error) => {
    console.error(error);
    for (const browser of Object.values(launched)) await browser.close().catch(() => {});
    process.exit(1);
});

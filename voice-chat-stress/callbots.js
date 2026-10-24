#!/usr/bin/env node
// Puts bots on BrowserStack machines and real phones (iPhones included) in one
// at-chat.app call and reports what each of them sent and received, using the
// same instrumentation and table as run.js. See README.md.
//
// Driven over Selenium rather than Playwright, so it only needs plain HTTPS to
// BrowserStack; the bots' own browsers connect to at-chat.app themselves.
// Bots sign up with throwaway Guerrilla Mail addresses and read their login
// codes from there, and their accounts and sessions are kept in logins/ so later
// runs reuse them.

const fs = require("fs");
const path = require("path");
const { Builder, By, Key, until } = require("selenium-webdriver");
const { HttpsProxyAgent } = require("https-proxy-agent");
const { summarise, log } = require("./run.js");

const TARGET = "https://at-chat.app";
const MAIL_API = "https://api.guerrillamail.com/ajax.php";
const accountsFile = path.join(__dirname, "logins", "callbots.json");
const instrumentSource = fs.readFileSync(path.join(__dirname, "instrument.js"), "utf8").trim().replace(/;$/, "");

const CHROME_ARGS = ["--use-fake-ui-for-media-stream", "--use-fake-device-for-media-stream"];
const FIREFOX_PREFS = { "media.navigator.streams.fake": true, "media.navigator.permission.disabled": true };

// The first one makes the test guild, which is easiest on a desktop layout.
const DEFAULT_PLATFORMS = [
    { name: "Windows 11 Chrome", os: "Windows", osVersion: "11", browser: "chrome" },
    { name: "iPhone 17 Pro iOS 26", device: "iPhone 17 Pro", osVersion: "26", browser: "safari" },
    { name: "Galaxy S24 Android 16", device: "Samsung Galaxy S24", osVersion: "16.0", browser: "chrome" },
    { name: "Windows 11 Firefox", os: "Windows", osVersion: "11", browser: "firefox" },
    { name: "macOS Tahoe Safari", os: "OS X", osVersion: "Tahoe", browser: "safari" },
];

function parseArgs(argv) {
    const args = { platforms: DEFAULT_PLATFORMS, duration: 60, warmup: 15, video: true, target: TARGET };
    const rest = argv.slice(2);
    for (let i = 0; i < rest.length; i++) {
        const flag = rest[i];
        const value = () => rest[++i];
        if (flag === "--platforms") args.platforms = JSON.parse(fs.readFileSync(value(), "utf8"));
        else if (flag === "--duration") args.duration = parseInt(value(), 10);
        else if (flag === "--warmup") args.warmup = parseInt(value(), 10);
        else if (flag === "--no-video") args.video = false;
        else throw new Error("Unknown flag " + flag);
    }
    return args;
}

// --- Guerrilla Mail ---
//
// Throwaway inboxes with a plain HTTPS API and no sign-up of their own. An
// address is kept by its user name, which claims it back on a later run.

const proxyAgent = process.env.HTTPS_PROXY ? new HttpsProxyAgent(process.env.HTTPS_PROXY) : undefined;

function mailApi(params) {
    const https = require("https");
    const url = MAIL_API + "?" + new URLSearchParams(params).toString();
    return new Promise((resolve, reject) => {
        https
            .get(url, { agent: proxyAgent }, (response) => {
                let data = "";
                response.on("data", (chunk) => (data += chunk));
                response.on("end", () => {
                    if (response.statusCode >= 400) reject(new Error(params.f + " " + response.statusCode + " " + data));
                    else resolve(JSON.parse(data));
                });
            })
            .on("error", reject);
    });
}

async function newMailbox(index) {
    const created = await mailApi({ f: "get_email_address", lang: "en" });
    const user = "atchat-callbot-" + index + "-" + Math.random().toString(36).slice(2, 8);
    const claimed = await mailApi({ f: "set_email_user", email_user: user, lang: "en", sid_token: created.sid_token });
    return { address: claimed.email_addr, user };
}

async function waitForLoginCode(mailbox) {
    const session = await mailApi({ f: "set_email_user", email_user: mailbox.user, lang: "en" });
    const token = session.sid_token;
    for (let i = 0; i < 60; i++) {
        const inbox = await mailApi({ f: "check_email", seq: 0, sid_token: token });
        const login = (inbox.list || []).find((mail) => mail.mail_subject === "Login code" || /at-chat/.test(mail.mail_from));
        if (login) {
            const mail = await mailApi({ f: "fetch_email", email_id: login.mail_id, sid_token: token });
            // BackendExtra.loginEmailContent puts each digit in an element of its own.
            const text = mail.mail_body.replace(/<[^>]*>/g, " ");
            const between = /Here is your code\.?([\s\d]*)Please/.exec(text);
            const match = between && /^\d{8}$/.exec(between[1].replace(/\s/g, "")) ? [null, between[1].replace(/\s/g, "")] : null;
            if (match) {
                await mailApi({ f: "del_email", "email_ids[]": login.mail_id, sid_token: token }).catch(() => {});
                return match[1];
            }
        }
        await new Promise((resolve) => setTimeout(resolve, 3000));
    }
    throw new Error("No login code arrived at " + mailbox.address);
}

// --- BrowserStack ---

function capsFor(p) {
    const bstack = {
        userName: process.env.BROWSERSTACK_USERNAME,
        accessKey: process.env.BROWSERSTACK_ACCESS_KEY,
        buildName: "at-chat call bots",
        sessionName: p.name,
        idleTimeout: 300,
    };
    const caps = { "bstack:options": bstack, browserName: p.browser };
    if (p.device) {
        bstack.deviceName = p.device;
        bstack.osVersion = p.osVersion;
        bstack.realMobile = "true";
        // Safari's camera and mic prompt, which nobody is there to answer.
        if (p.browser === "safari") bstack.autoAcceptAlerts = "true";
        if (p.browser === "chrome") caps["goog:chromeOptions"] = { args: CHROME_ARGS };
    } else {
        bstack.os = p.os;
        bstack.osVersion = p.osVersion;
        caps.browserVersion = "latest";
        if (p.browser === "chrome") caps["goog:chromeOptions"] = { args: CHROME_ARGS };
        if (p.browser === "edge") caps["ms:edgeOptions"] = { args: CHROME_ARGS };
        if (p.browser === "firefox") caps["moz:firefoxOptions"] = { prefs: FIREFOX_PREFS };
    }
    return caps;
}

async function startDriver(p) {
    const builder = new Builder().usingServer("https://hub-cloud.browserstack.com/wd/hub");
    if (proxyAgent) builder.usingHttpAgent(proxyAgent);
    const driver = await builder.withCapabilities(capsFor(p)).build();
    await driver.manage().setTimeouts({ script: 30000, pageLoad: 60000 });
    return driver;
}

async function click(driver, id) {
    const element = await driver.wait(until.elementLocated(By.id(id)), 30000);
    await driver.wait(until.elementIsVisible(element), 10000);
    await element.click();
}

async function type(driver, id, text) {
    const element = await driver.wait(until.elementLocated(By.id(id)), 30000);
    await element.clear().catch(() => {});
    await element.sendKeys(text);
}

// The page's own text inputs, read for the invite link's copy box.
async function inviteLinkOnPage(driver) {
    for (let i = 0; i < 30; i++) {
        const value = await driver.executeScript(
            "return Array.from(document.querySelectorAll('input')).map(function (i) { return i.value; }).find(function (v) { return v.indexOf('/join/') !== -1; }) || null;"
        );
        if (value) return value;
        await new Promise((resolve) => setTimeout(resolve, 1000));
    }
    throw new Error("No invite link appeared");
}

// --- accounts ---

function loadAccounts() {
    return fs.existsSync(accountsFile) ? JSON.parse(fs.readFileSync(accountsFile, "utf8")) : { bots: [] };
}

function saveAccounts(accounts) {
    fs.mkdirSync(path.dirname(accountsFile), { recursive: true });
    fs.writeFileSync(accountsFile, JSON.stringify(accounts, null, 2));
}

// Null on BrowserStack's iPhones, which don't implement reading cookies, so
// those bots log in by email every run.
async function sessionCookie(driver) {
    const cookie = await driver.manage().getCookie("sid").catch(() => null);
    return cookie ? cookie.value : null;
}

// Logs the bot in, signing it up first if it has never been. `startUrl` is the
// invite link for everyone but the bot that makes the guild.
async function logIn(bot, account, startUrl) {
    try {
        await logInHelper(bot, account, startUrl);
    } catch (error) {
        await saveFailureScreenshot(bot, "login");
        throw new Error(bot.label + " couldn't log in: " + error.message);
    }
}

async function logInHelper(bot, account, startUrl) {
    const driver = bot.driver;
    if (account.sid) {
        await driver.get(TARGET + "/");
        // Replacing, not adding: the first visit already got a fresh sid, and
        // with two the server can pick the logged out one.
        await driver.manage().deleteCookie("sid").catch(() => {});
        await driver.manage().addCookie({ name: "sid", value: account.sid, path: "/", secure: true, httpOnly: true });
        await driver.get(startUrl || TARGET + "/");
        if ((await waitForLoginState(driver, ["in", "email"])) === "in") return;
        log(bot.label, "saved session no longer works, logging in again");
    }

    await driver.get(startUrl || TARGET + "/");
    if (!startUrl) await click(driver, "homePage_loginButton");
    if ((await waitForLoginState(driver, ["in", "email"])) === "in") {
        account.sid = await sessionCookie(driver);
        saveAccounts(bot.accounts);
        return;
    }
    await type(driver, "loginForm_emailInput", account.mailbox.address);
    await click(driver, "loginForm_loginButton");
    const code = await waitForLoginCode(account.mailbox);
    log(bot.label, "got login code");
    await type(driver, "loginForm_loginCodeInput", code);

    if ((await waitForLoginState(driver, ["new", "in"])) === "new") {
        await type(driver, "loginForm_name", "Call bot " + bot.index);
        await click(driver, "loginForm_submit");
        // A click on Submit sometimes doesn't land on BrowserStack's phones,
        // so Enter in the name field is the second try.
        if ((await waitForLoginState(driver, ["in"], 10)) !== "in") {
            await driver.findElement(By.id("loginForm_name")).sendKeys(Key.ENTER);
        }
        if ((await waitForLoginState(driver, ["in"])) !== "in") throw new Error("still not logged in after picking a name");
    }
    account.sid = await sessionCookie(driver);
    saveAccounts(bot.accounts);
}

// One script polled in a loop rather than two element waits raced against each
// other, since BrowserStack's iPhones end the session when two commands
// overlap. Phones and desktops lay the app out differently, so being logged in
// is judged by the login form having gone and the guild UI being there.
async function waitForLoginState(driver, wanted = ["new", "in", "email"], seconds = 40) {
    for (let i = 0; i < seconds; i++) {
        const state = await driver.executeScript(
            "if (document.getElementById('loginForm_name')) return 'new';" +
                "if (document.querySelector('[id^=\"guild_\"]')) return 'in';" +
                "if (document.getElementById('loginForm_emailInput')) return 'email';" +
                "return 'waiting';"
        );
        if (wanted.includes(state)) return state;
        await new Promise((resolve) => setTimeout(resolve, 1000));
    }
    return "waiting";
}

async function saveFailureScreenshot(bot, step) {
    const png = await bot.driver.takeScreenshot().catch(() => null);
    if (!png) return;
    const file = path.join(bot.out, bot.label.replace(/ /g, "-") + "-" + step + "-failed.png");
    fs.writeFileSync(file, png, "base64");
    log(bot.label, "screenshot of the failure in " + file);
}

// --- the call ---

async function joinCall(bot, args) {
    try {
        await joinCallHelper(bot, args);
    } catch (error) {
        await saveFailureScreenshot(bot, "join");
        throw new Error(bot.label + " couldn't join the call: " + error.message);
    }
}

async function joinCallHelper(bot, args) {
    const driver = bot.driver;
    await driver.get(bot.channelUrl);
    await driver.wait(until.elementLocated(By.id("guild_voiceChat")), 30000);
    // Injected after load rather than before it, which Selenium can't do. That
    // is still in time: voice-chat.js only opens the room socket and builds its
    // encoders and decoders on joining.
    await driver.executeScript(
        "(" +
            instrumentSource +
            ")(" +
            JSON.stringify({ fakeMedia: false, noVideo: !args.video, toneHz: 440, hue: bot.index * 40, label: "bot" + bot.index }) +
            ");"
    );
    await click(driver, "guild_voiceChat");
    await click(driver, "guild_startVoiceChat");
    for (let i = 0; i < 30; i++) {
        if (await driver.executeScript("return !!(window.__stress && window.__stress.roomUrl);")) return;
        await new Promise((resolve) => setTimeout(resolve, 1000));
    }
    throw new Error(bot.label + " never opened the room socket");
}

async function collect(bot) {
    const stats = JSON.parse(
        await bot.driver.executeScript(
            "var s = window.__stress; return JSON.stringify({ elapsedMs: performance.now() - s.startedAt, received: s.received, sent: s.sent, decoded: s.decoded, maxQueue: s.maxQueue, socketMaxBuffered: s.socketMaxBuffered, socketCloses: s.socketCloses, lagSamples: s.lagSamples, errors: s.errors, roomUrl: s.roomUrl, audioContexts: s.audioContextStates() });"
        )
    );
    const errorBox = await bot.driver
        .findElement(By.id("voiceChat_errorBox"))
        .then((element) => element.getText())
        .catch(() => null);
    return { bot, stats, errorBox };
}

async function run(args) {
    if (!process.env.BROWSERSTACK_USERNAME || !process.env.BROWSERSTACK_ACCESS_KEY) {
        throw new Error("Set BROWSERSTACK_USERNAME and BROWSERSTACK_ACCESS_KEY");
    }
    const accounts = loadAccounts();
    const out = path.join(__dirname, "results", "callbots-" + new Date().toISOString().replace(/[:.]/g, "-"));
    fs.mkdirSync(out, { recursive: true });

    const bots = args.platforms.map((platform, i) => ({
        index: i + 1,
        platform,
        label: "bot" + (i + 1) + " " + platform.name,
        accounts,
        out,
    }));
    try {
        for (const bot of bots) {
            if (!accounts.bots[bot.index - 1]) {
                accounts.bots[bot.index - 1] = { mailbox: await newMailbox(bot.index) };
                saveAccounts(accounts);
            }
        }

        log("starting " + bots.length + " BrowserStack sessions");
        await Promise.all(
            bots.map(async (bot) => {
                bot.driver = await startDriver(bot.platform);
                log(bot.label, "session started");
            })
        );

        // The first bot owns the test guild and its invite link.
        const [owner, ...others] = bots;
        await logIn(owner, accounts.bots[0], null);
        if (!accounts.inviteUrl) {
            log(owner.label, "creating the test guild");
            await click(owner.driver, "guild_createGuild");
            await type(owner.driver, "newGuildName", "Call bot test");
            await click(owner.driver, "guild_createGuildSubmit");
            await click(owner.driver, "guild_inviteLinkCreatorRoute");
            await click(owner.driver, "guild_createInviteLink");
            accounts.inviteUrl = await inviteLinkOnPage(owner.driver);
            const guildPath = /\/g\/\d+/.exec(accounts.inviteUrl)[0];
            accounts.channelUrl = TARGET + guildPath + "/c/0";
        }
        saveAccounts(accounts);
        log("invite link", accounts.inviteUrl);

        await Promise.all(
            others.map(async (bot) => {
                await logIn(bot, accounts.bots[bot.index - 1], accounts.inviteUrl);
                log(bot.label, "logged in");
            })
        );
        saveAccounts(accounts);

        for (const bot of bots) bot.channelUrl = accounts.channelUrl;
        await Promise.all(
            bots.map(async (bot) => {
                await joinCall(bot, args);
                log(bot.label, "in the call");
            })
        );

        log("warming up for " + args.warmup + "s");
        await new Promise((resolve) => setTimeout(resolve, args.warmup * 1000));
        await Promise.all(bots.map((bot) => bot.driver.executeScript("window.__stress.reset();")));
        log("measuring for " + args.duration + "s");
        await new Promise((resolve) => setTimeout(resolve, args.duration * 1000));

        const results = await Promise.all(bots.map(collect));
        const summary = summarise(results, args, 0);
        console.log("\n" + summary + "\n");
        fs.writeFileSync(path.join(out, "summary.txt"), summary + "\n");
        fs.writeFileSync(
            path.join(out, "stats.json"),
            JSON.stringify(results.map(({ bot, stats, errorBox }) => ({ bot: bot.label, errorBox, ...stats })), null, 2)
        );
        for (const bot of bots) {
            const png = await bot.driver.takeScreenshot().catch(() => null);
            if (png) fs.writeFileSync(path.join(out, bot.label.replace(/ /g, "-") + ".png"), png, "base64");
        }
        log("results in " + out);
    } finally {
        await Promise.all(bots.filter((bot) => bot.driver).map((bot) => bot.driver.quit().catch(() => {})));
    }
}

run(parseArgs(process.argv)).catch((error) => {
    console.error(error);
    process.exit(1);
});

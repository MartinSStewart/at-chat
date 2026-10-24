// Opens at-chat.app on BrowserStack machines and real phones and checks what a
// call needs there: getUserMedia, the AudioContext's sample rate, and a real
// encode and decode round trip for each codec voice-chat.js uses, since a
// browser can say it supports a codec and then fail to use it. See README.md.
//
// Selenium rather than Playwright, because it talks to BrowserStack over plain
// HTTPS, which works from behind proxies that don't pass websockets, and
// because it can drive Safari on real iPhones.
const { Builder } = require("selenium-webdriver");
const { HttpsProxyAgent } = require("https-proxy-agent");
const fs = require("fs");
const path = require("path");

const user = process.env.BROWSERSTACK_USERNAME;
const key = process.env.BROWSERSTACK_ACCESS_KEY;

const CHROME_ARGS = ["--use-fake-ui-for-media-stream", "--use-fake-device-for-media-stream"];
const FIREFOX_PREFS = { "media.navigator.streams.fake": true, "media.navigator.permission.disabled": true };

const DEFAULT_PLATFORMS = [
    { name: "Windows 11 Chrome", os: "Windows", osVersion: "11", browser: "chrome" },
    { name: "Windows 11 Firefox", os: "Windows", osVersion: "11", browser: "firefox" },
    { name: "Windows 10 Edge", os: "Windows", osVersion: "10", browser: "edge" },
    { name: "macOS Tahoe Safari", os: "OS X", osVersion: "Tahoe", browser: "safari" },
    { name: "iPhone 17 Pro iOS 26", device: "iPhone 17 Pro", osVersion: "26", browser: "safari" },
    { name: "iPhone 15 iOS 27", device: "iPhone 15", osVersion: "27", browser: "safari" },
    { name: "Galaxy S24 Android 16", device: "Samsung Galaxy S24", osVersion: "16.0", browser: "chrome" },
    { name: "Moto G71 Android 11", device: "Motorola Moto G71 5G", osVersion: "11.0", browser: "chrome" },
    { name: "Galaxy M32 Android 11", device: "Samsung Galaxy M32", osVersion: "11.0", browser: "chrome" },
];

const platforms = process.argv[2] ? JSON.parse(fs.readFileSync(process.argv[2], "utf8")) : DEFAULT_PLATFORMS;

function capsFor(p) {
    const bstack = {
        userName: user,
        accessKey: key,
        buildName: "at-chat call capability probe",
        sessionName: p.name,
        idleTimeout: 120,
    };
    const caps = { "bstack:options": bstack };
    if (p.device) {
        bstack.deviceName = p.device;
        bstack.osVersion = p.osVersion;
        bstack.realMobile = "true";
        caps.browserName = p.browser;
        if (p.browser === "chrome") caps["goog:chromeOptions"] = { args: CHROME_ARGS };
        // Safari's camera and mic prompt, which nobody is there to answer.
        if (p.browser === "safari") bstack.autoAcceptAlerts = "true";
    } else {
        bstack.os = p.os;
        bstack.osVersion = p.osVersion;
        caps.browserName = p.browser;
        caps.browserVersion = p.browserVersion || "latest";
        if (p.browser === "chrome" || p.browser === "edge") {
            caps[p.browser === "chrome" ? "goog:chromeOptions" : "ms:edgeOptions"] = { args: CHROME_ARGS };
        }
        if (p.browser === "firefox") caps["moz:firefoxOptions"] = { prefs: FIREFOX_PREFS };
    }
    return caps;
}

// Runs in the page. Every step has its own timeout so one hung promise can't
// eat the whole session.
const pageProbe = function (done) {
    const out = { ua: navigator.userAgent };
    const timeout = (ms, label) => new Promise((_, reject) => setTimeout(() => reject(new Error(label + " timed out")), ms));
    const guard = (promise, ms, label) => Promise.race([promise, timeout(ms, label)]);

    async function videoRoundTrip(codec) {
        const result = {};
        const config = { codec, width: 320, height: 240, bitrate: 500000, framerate: 30 };
        if (codec.startsWith("avc1")) config.avc = { format: "annexb" };
        try {
            result.supported = (await VideoEncoder.isConfigSupported(config)).supported;
        } catch (e) {
            result.supported = String(e);
            return result;
        }
        const chunks = [];
        let encodeError = null;
        try {
            const encoder = new VideoEncoder({ output: (chunk) => chunks.push(chunk), error: (e) => (encodeError = String(e)) });
            encoder.configure(config);
            const canvas = document.createElement("canvas");
            canvas.width = 320;
            canvas.height = 240;
            const g = canvas.getContext("2d");
            for (let i = 0; i < 10; i++) {
                g.fillStyle = "hsl(" + i * 36 + ",80%,50%)";
                g.fillRect(0, 0, 320, 240);
                const frame = new VideoFrame(canvas, { timestamp: i * 33333 });
                encoder.encode(frame, { keyFrame: i % 5 === 0 });
                frame.close();
            }
            await guard(encoder.flush(), 8000, "video encode flush");
            encoder.close();
        } catch (e) {
            encodeError = encodeError || String(e);
        }
        result.encoded = chunks.length;
        if (encodeError) result.encodeError = encodeError;
        if (chunks.length === 0) return result;

        let decoded = 0;
        let decodeError = null;
        try {
            const decoder = new VideoDecoder({ output: (f) => { decoded++; f.close(); }, error: (e) => (decodeError = String(e)) });
            decoder.configure({ codec });
            for (const chunk of chunks) decoder.decode(chunk);
            await guard(decoder.flush(), 8000, "video decode flush");
            decoder.close();
        } catch (e) {
            decodeError = decodeError || String(e);
        }
        result.decoded = decoded;
        if (decodeError) result.decodeError = decodeError;
        return result;
    }

    async function opusRoundTrip(sampleRate) {
        const result = {};
        const chunks = [];
        try {
            const encoder = new AudioEncoder({ output: (c) => chunks.push(c), error: (e) => (result.encodeError = String(e)) });
            encoder.configure({ codec: "opus", sampleRate, numberOfChannels: 1, bitrate: 64000 });
            for (let i = 0; i < 25; i++) {
                const data = new Float32Array(960);
                for (let j = 0; j < 960; j++) data[j] = Math.sin((i * 960 + j) / 20) * 0.3;
                const audio = new AudioData({ format: "f32-planar", sampleRate, numberOfFrames: 960, numberOfChannels: 1, timestamp: Math.round(((i * 960) / sampleRate) * 1e6), data });
                encoder.encode(audio);
                audio.close();
            }
            await guard(encoder.flush(), 8000, "opus encode flush");
            encoder.close();
        } catch (e) {
            result.encodeError = result.encodeError || String(e);
        }
        result.encoded = chunks.length;
        if (chunks.length === 0) return result;
        let decoded = 0;
        try {
            const decoder = new AudioDecoder({ output: (a) => { decoded++; a.close(); }, error: (e) => (result.decodeError = String(e)) });
            decoder.configure({ codec: "opus", sampleRate: 48000, numberOfChannels: 1 });
            for (const chunk of chunks) decoder.decode(chunk);
            await guard(decoder.flush(), 8000, "opus decode flush");
            decoder.close();
        } catch (e) {
            result.decodeError = result.decodeError || String(e);
        }
        result.decoded = decoded;
        return result;
    }

    (async () => {
        out.has = {
            VideoEncoder: typeof VideoEncoder !== "undefined",
            AudioEncoder: typeof AudioEncoder !== "undefined",
            requestVideoFrameCallback: typeof HTMLVideoElement !== "undefined" && "requestVideoFrameCallback" in HTMLVideoElement.prototype,
            AudioWorklet: typeof AudioWorkletNode !== "undefined",
        };
        try {
            const context = new AudioContext();
            out.audioContextRate = context.sampleRate;
            context.close();
        } catch (e) {
            out.audioContextRate = String(e);
        }
        try {
            const devices = await guard(navigator.mediaDevices.enumerateDevices(), 5000, "enumerateDevices");
            out.devices = devices.map((d) => d.kind).join(",");
        } catch (e) {
            out.devices = String(e);
        }
        try {
            const stream = await guard(navigator.mediaDevices.getUserMedia({ audio: true, video: true }), 8000, "getUserMedia");
            out.getUserMedia = stream.getTracks().map((t) => {
                const s = t.getSettings();
                return t.kind + " " + (s.width ? s.width + "x" + s.height : "") + (s.sampleRate ? s.sampleRate + "Hz" : "");
            });
            try {
                const context = new AudioContext({ sampleRate: 48000 });
                context.createMediaStreamSource(stream);
                out.micInto48kContext = "ok";
                context.close();
            } catch (e) {
                out.micInto48kContext = String(e);
            }
            stream.getTracks().forEach((t) => t.stop());
        } catch (e) {
            out.getUserMedia = String(e);
        }
        if (out.has.VideoEncoder) {
            out.vp8 = await videoRoundTrip("vp8");
            out.avc1 = await videoRoundTrip("avc1.42001E");
        }
        if (out.has.AudioEncoder) {
            out.opus48k = await opusRoundTrip(48000);
            if (typeof out.audioContextRate === "number" && out.audioContextRate !== 48000) {
                out["opus" + out.audioContextRate] = await opusRoundTrip(out.audioContextRate);
            }
        }
        done(out);
    })().catch((e) => done(Object.assign(out, { fatal: String(e) })));
};

async function probe(p) {
    const started = Date.now();
    let driver;
    try {
        const builder = new Builder().usingServer("https://hub-cloud.browserstack.com/wd/hub");
        if (process.env.HTTPS_PROXY) builder.usingHttpAgent(new HttpsProxyAgent(process.env.HTTPS_PROXY));
        driver = await builder.withCapabilities(capsFor(p)).build();
        await driver.manage().setTimeouts({ script: 90000, pageLoad: 60000 });
        await driver.get("https://at-chat.app/");
        // Started with a plain script and polled, because Safari on real
        // iPhones answers executeAsyncScript with `true` instead of the result.
        await driver.executeScript("window.__probe = null; (" + pageProbe.toString() + ")(function (r) { window.__probe = JSON.stringify(r); });");
        let result = null;
        for (let i = 0; i < 90 && result === null; i++) {
            await new Promise((resolve) => setTimeout(resolve, 1000));
            result = await driver.executeScript("return window.__probe;");
        }
        result = result === null ? { fatal: "probe never finished" } : JSON.parse(result);
        await driver.executeScript('browserstack_executor: {"action": "setSessionStatus", "arguments": {"status":"passed","reason": "probe ran"}}');
        return { platform: p.name, seconds: Math.round((Date.now() - started) / 1000), result };
    } catch (e) {
        return { platform: p.name, seconds: Math.round((Date.now() - started) / 1000), error: String(e).slice(0, 500) };
    } finally {
        if (driver) await driver.quit().catch(() => {});
    }
}

function cell(result) {
    if (result === undefined) return "-";
    if (typeof result === "string") return result.slice(0, 40);
    if (result.encoded === undefined) return "unsupported";
    const ok = result.encoded > 0 && result.decoded > 0 && !result.encodeError && !result.decodeError;
    return ok ? "ok" : "FAIL " + (result.encodeError || result.decodeError || "encoded " + result.encoded + " decoded " + result.decoded).slice(0, 60);
}

(async () => {
    if (!user || !key) throw new Error("Set BROWSERSTACK_USERNAME and BROWSERSTACK_ACCESS_KEY");
    // BrowserStack queues anything over the plan's parallel limit itself.
    const results = await Promise.all(platforms.map(probe));
    fs.mkdirSync(path.join(__dirname, "results"), { recursive: true });
    const file = path.join(__dirname, "results", "probe-" + new Date().toISOString().replace(/[:.]/g, "-") + ".json");
    fs.writeFileSync(file, JSON.stringify(results, null, 2));
    for (const { platform, result, error } of results) {
        console.log(platform);
        if (error) {
            console.log("  session failed: " + error);
            continue;
        }
        const mic = Array.isArray(result.getUserMedia) ? result.getUserMedia.join(", ") : result.getUserMedia;
        const opusRates = Object.keys(result).filter((k) => k.startsWith("opus"));
        console.log("  " + result.ua);
        console.log("  getUserMedia: " + mic + ", AudioContext " + result.audioContextRate + "Hz");
        console.log(
            "  vp8: " + cell(result.vp8) + "   avc1: " + cell(result.avc1) + "   " +
                opusRates.map((k) => k + ": " + cell(result[k])).join("   ")
        );
        if (result.fatal) console.log("  " + result.fatal);
    }
    console.log("\nFull results in " + file);
})().catch((e) => {
    console.error(e.message);
    process.exit(1);
});

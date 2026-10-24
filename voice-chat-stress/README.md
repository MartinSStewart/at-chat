# Voice chat stress test

Puts several bots in one voice call, mixing Chromium, Firefox and WebKit, keeps them there
for a while and prints what each one sent, received and decoded.

```
cd voice-chat-stress
npm install
npx playwright install chromium firefox webkit
```

## Against a local backend

Start `lamdera live` and the rust server (`npm run rust-server`) from the repo root, then:

```
node run.js                       # 8 bots, camera on, 60s
node run.js --no-video --users 8  # audio only
node run.js --users 4 --browsers firefox,webkit --duration 120
```

The bots sign themselves up through the invite link of the first guild, reading their login
codes off the console the way you would in development, and all join the call in
`/g/0/c/0`. A run against a backend that already has them just logs them back in.

## Against at-chat.app

Bots there can't read their login codes, so each one is logged in by hand once:

```
node run.js login --target https://at-chat.app --name bot1
```

A browser opens. Log in as that bot, join the guild the call will be in, then press enter
in the terminal. Its cookies are saved in `logins/bot1.json` (gitignored). Repeat for as
many bots as you want, then:

```
node run.js --target https://at-chat.app --channel-url https://at-chat.app/g/<guild>/c/<channel>
```

Join the same call yourself from a phone or another browser to hear what it's like with the
bots in it. Each bot sends a tone at its own pitch, and in WebKit a canvas in its own colour.

## On BrowserStack

Any entry in `--browsers` of the form `bs:<browser>@<os>/<version>` runs that bot on
BrowserStack, in its own session, so each such bot is a separate machine. Local and
BrowserStack bots can share one call, which helps when the plan has fewer parallel
sessions than you want bots.

```
export BROWSERSTACK_USERNAME=... BROWSERSTACK_ACCESS_KEY=...
node run.js --target https://at-chat.app --channel-url https://at-chat.app/g/<guild>/c/<channel> \
  --browsers "bs:chrome@Windows/11,bs:edge@Windows/10,bs:playwright-firefox@OS X/Sonoma,bs:playwright-webkit@OS X/Ventura,bs:android@Samsung Galaxy S23/13.0,chromium,firefox,webkit"
```

- `bs:chrome`, `bs:edge`, `bs:playwright-chromium`, `bs:playwright-firefox` and
  `bs:playwright-webkit` run on Windows or macOS VMs (`Windows/10`, `Windows/11`,
  `OS X/Ventura`, `OS X/Sonoma` and so on, as BrowserStack's capability builder lists
  them). The VMs have no camera or mic, so they get the same fake devices as local bots.
- `bs:android@<device>/<os version>` is Chrome on a real Android phone, which uses its own
  camera and mic. BrowserStack calls this beta. Playwright can't drive real iPhones.
- They can't reach `lamdera live` on your machine, so `--target` has to be a deployed
  at-chat, with saved logins as above.

None of this has been run against BrowserStack yet: it follows their documentation
(`wss://cdp.browserstack.com/playwright?caps=...`, `args` for Chromium-based browsers,
`firefox_user_prefs` for Firefox). Expect the first run to need adjusting.

## Checking codecs on many devices

`probe.js` opens at-chat.app on a list of BrowserStack machines and real phones, and on
each one checks getUserMedia, the AudioContext's sample rate, and a real encode and decode
of a few VP8, H.264 and opus frames. Asking `isConfigSupported` alone isn't enough: the
Linux Mint bug was a codec that said yes and then failed. It doesn't log in or join a call,
so it needs no saved logins, and each machine takes about 20 seconds.

```
node probe.js                  # the default list in probe.js
node probe.js platforms.json   # your own list, in the same shape as that default list
```

Device and OS names are the ones BrowserStack's capability builder uses. Unlike the
Playwright bots it also reaches real iPhones.

## A call on BrowserStack machines and real phones

`callbots.js` puts five bots in one at-chat.app call, by default Chrome and Firefox on
Windows 11, Safari on macOS, and Safari and Chrome on a real iPhone and Galaxy, and prints
the same table as `run.js`. It drives them over Selenium, so unlike the Playwright bots it
only needs plain HTTPS to BrowserStack and runs fine behind a proxy that blocks websockets.

```
export BROWSERSTACK_USERNAME=... BROWSERSTACK_ACCESS_KEY=...
node callbots.js                       # 60s measured after 15s warm-up
node callbots.js --duration 120 --no-video
node callbots.js --platforms platforms.json   # same shape as DEFAULT_PLATFORMS
```

The first run signs each bot up with a throwaway Guerrilla Mail address and reads its
login code from there, and the first bot makes a guild called "Call bot test" that the
rest join. The accounts, their sessions and the guild's invite are kept in
`logins/callbots.json` (gitignored), so later runs log straight back in. Join that guild
yourself to be in the call with them.

## Reading the results

The table goes to the terminal and to `results/<time>/summary.txt`, with every number in
`stats.json` and a screenshot of each bot next to it.

- **sent a/v per s**: audio packets and video frames this bot sent. Audio should be 50.
- **recv audio/s per sender**: the slowest and fastest sender as heard by this bot. Anything
  well under 50 means packets from someone are being lost or never sent: compare against
  that sender's own sent column to tell which.
- **worst audio gap, gaps>100ms**: the longest silence between two audio packets from the
  same sender, and how often it went past 100ms.
- **decoded a/v per s**: everything this bot's decoders produced. Should match what arrived.
- **main lag**: how late a 100ms timer fired on this bot's main thread. Past about 50ms the
  bot itself can't keep up, and every number above it says more about the machine running
  the bots than about at-chat. The CPU busy line says the same for the whole machine.

`--profile` CPU-profiles the first Chromium bot's main thread while measuring and prints
the functions it spent the most time in. The full profile is saved as a `.cpuprofile`, which
the Performance panel of Chrome's dev tools can open.

## Other flags

- `--warmup <s>` seconds in the call before measuring starts (default 15)
- `--headed` shows the browser windows
- `--bots bot1,bot3` picks which saved logins to use
- `--use-saved-logins` uses saved logins against a local backend too
- `--out <dir>` where the results go
- `CHROMIUM_PATH=...` runs a Chromium other than Playwright's own
- `STRESS_DEBUG=1` also prints the bots' console lines that mention calls or media

## Running it on Linux without a sound card

Firefox won't start an AudioContext with no audio output at all, so its bots send nothing.
A null PulseAudio sink is enough:

```
apt-get install -y pulseaudio
pulseaudio --start --exit-idle-time=-1
pactl load-module module-null-sink sink_name=stress
```

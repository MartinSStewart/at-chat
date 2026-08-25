# Local speech to text

Speech recognition that runs in the browser, for transcribing what you say in a
call without the audio leaving the machine.

## What this is

`k2-fsa/web-assembly-asr-sherpa-ncnn-en` on Hugging Face is a *static* space: it
contains the emscripten output, not the sources, so there is nothing to build.
`scripts/fetch-speech-to-text-model.sh` downloads the four files it publishes and
checks them against the hashes recorded at a pinned revision:

| file | size | what it is |
| --- | --- | --- |
| `sherpa-ncnn.js` | 8KB | hand-written wrapper over the C API |
| `sherpa-ncnn-wasm-main.js` | 79KB | emscripten glue |
| `sherpa-ncnn-wasm-main.wasm` | 1.7MB | sherpa-ncnn itself |
| `sherpa-ncnn-wasm-main.data` | 141MB | the model, in an emscripten filesystem image |

All four are gitignored. Run the script once after cloning.

The model is a streaming zipformer transducer trained on English read speech. It
transcribes as you talk rather than waiting for you to stop, and decides where
one utterance ends from trailing silence.

## Running it

```
./scripts/fetch-speech-to-text-model.sh
```

then open `/speech-to-text/demo.html`, which listens on the microphone. It also
takes an audio file, which goes through the same path, so it can be checked
without a microphone.

## Using it from a call

`speech-to-text.js` hides the worker behind four callbacks:

```js
const stt = createSpeechToText({
    onReady: function () {},
    onPartial: function (text) {},
    onFinal: function (text) {},
    onError: function (message) {},
});
```

`stt.feed(samples)` wants mono 48kHz `Float32Array` blocks, which is exactly what
the capture worklet in `elm-pkg-js/voice-chat.js` already posts on its way to the
audio encoder — so a call transcribes the microphone as recorded, not the opus
the far end receives. `stt.flush()` at the end of speech emits the last
utterance; `stt.stop()` tears the worker down.

## What to know before building on it

* **No punctuation and no casing.** Output looks like
  `AFTER EARLY NIGHTFALL THE YELLOW LAMPS WOULD LIGHT UP`. The model's vocabulary
  has neither, so this cannot be configured away — it needs a second pass, or a
  different model.
* **English only.**
* **Trained on read speech**, so accuracy on a relaxed conversation with
  crosstalk is well below what the demo suggests.
* **One core, roughly 0.6x real time**, measured in Chromium on this machine.
  It keeps up, but a slow machine already encoding video for a call has less
  headroom than that number suggests.
* **141MB on first load**, cached afterwards. Since the files are gitignored they
  are not part of a deploy: serving this in production means either committing
  them, putting them behind a CDN, or pointing `Module.locateFile` in
  `stt-worker.js` at Hugging Face so the browser fetches the model from there.
  Inference stays local in every case.

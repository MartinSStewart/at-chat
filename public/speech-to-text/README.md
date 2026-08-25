# Local speech to text

Speech recognition that runs in the browser, for transcribing what you say in a
call without the audio leaving the machine.

## Getting it

```
./scripts/fetch-speech-to-text-models.py            # all three, about 250MB of downloads
./scripts/fetch-speech-to-text-models.py zipformer-small-zh-en   # or just one
```

Then open `/speech-to-text/demo.html`, pick a model, and talk. The page also
takes an audio file, which goes through the same path, and has a **Compare all
models** button that runs every model over the same audio and reports what each
one costs.

Everything under `models/` is gitignored.

## The models

All three stream: they transcribe while you talk rather than waiting for you to
stop, and decide where one utterance ends from trailing silence. Download is
what the browser fetches once and caches: the recogniser binary plus the model.

| | download | engine |
| --- | --- | --- |
| `zipformer-small-zh-en` | 55MB | sherpa-ncnn |
| `zipformer-20m-en` | 58MB | sherpa-onnx (SIMD) |
| `zipformer-en` | 143MB | sherpa-ncnn |

Measured in Chromium on one machine, over a 6.6s LibriSpeech clip, which is
read speech and so flatters all three:

| | load | first text | speed | transcript |
| --- | --- | --- | --- | --- |
| `zipformer-small-zh-en` | 600ms | 300ms | 0.26x | …THE SQUALID QUARTER OF THE **BRAWS** |
| `zipformer-20m-en` | 2685ms | 425ms | 0.18x | **(drops the first four words)** … THE **BRAFFLELS** |
| `zipformer-en` | 2785ms | 712ms | 0.55x | (correct throughout) |

Speed is decode time over audio length, so under 1.00x keeps up with a
conversation; the rest of that core is what is left for encoding call video.
One clip is not an accuracy benchmark — record yourself and press Compare.

`zipformer-20m-en` decodes fastest but was the least accurate of the three here,
losing the opening words entirely. Its fp32 export gives the same transcript for
twice the download, which is why the int8 one is what the fetch script builds.

## Nothing here is compiled

The WebAssembly is published prebuilt: sherpa-ncnn as a static Hugging Face
space, sherpa-onnx as a release asset from the project's own workflow. The
`.wasm` is the recogniser and does not care which model it loads, so where the
model is not the one a build shipped with,
`scripts/build-speech-to-text-package.py` repacks the emscripten bundle around
it — the `.data` is a plain concatenation and the offsets live in a manifest, so
this is a rewrite rather than a build. Every download is checked against a
recorded sha256.

## The ncnn models are loaded without the emscripten glue

Upstream ships 77KB of generated, minified JavaScript beside the 1.7MB `.wasm`,
plus an 8KB wrapper over the C API. `ncnn-recognizer.js` replaces both. That is
not really about the bytes — it is that the loader is the half of the pair a
person can read, and 77KB of minified output is not readable.

It matters because **the import list is the security boundary**. The `.wasm` can
do exactly what the JavaScript behind those imports lets it, and this build
imports fifteen functions:

    __cxa_throw  exit  abort  fd_write  fd_close  fd_read  fd_seek
    __syscall_openat  __syscall_fcntl64  __syscall_ioctl  strftime_l
    environ_get  environ_sizes_get  emscripten_resize_heap  emscripten_memcpy_js

None of them reaches the network, the DOM or the page. `openat` and `read` are
answered from a read-only table built out of the `.data` blob, so the only files
that exist are the seven the model is made of. Whatever else the binary contains,
that is the entire set of things it can do — a stronger statement than "the
upstream loader looked fine", and one checkable in a screenful rather than by
reading generated code.

The upstream loader is not doing anything alarming, for the record: it contains
no `eval` and no `new Function`. It is simply large and generated, and carries an
XHR downloader, a POSIX filesystem stack and a TTY shim for a program that opens
seven files read-only and prints a few lines.

The minified export and import names are checked at load, so a build whose layout
has shifted fails with a clear message rather than computing something wrong.
Which build that is stays pinned by revision and sha256 in the fetch script.

This was verified equivalent to the upstream glue rather than merely similar:
over 43 seconds of audio and five endpoint cycles, both paths emitted the same 98
partials and finals, in the same order, with identical text.

`zipformer-20m-en` still loads the upstream way. sherpa-onnx has a much larger
surface — 40 imports against 15, and a 54KB C API wrapper covering every model
type it supports — so the same treatment there is a bigger job than this was.

## Using it from a call

```js
const stt = createSpeechToText({
    model: "zipformer-small-zh-en",
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

* **No punctuation and no casing**, in any of them. Output looks like
  `AFTER EARLY NIGHTFALL THE YELLOW LAMPS WOULD LIGHT UP`. The vocabularies have
  neither, so this cannot be configured away.
* **Trained on read speech**, so accuracy on a relaxed conversation with
  crosstalk is well below what the table above suggests.
* **One core.** Decoding is in a worker so it does not stall the main thread,
  but it still competes with the call's video encoding for CPU.
* **Not part of a deploy.** `models/` is gitignored and the deploy builds from
  git, so serving this in production means committing the files, putting them
  behind a CDN, or pointing the loader at a remote host. Inference stays
  local in every case.
* **The 1.7MB `.wasm` is still not auditable.** Replacing the loader bounds
  what it can do; it does not tell you what it does.

## Why not Whisper, Moonshine or Parakeet

They lose on both counts that matter here. All are non-streaming: they transcribe
a finished segment, so text cannot appear until you stop talking, where these
three emit it mid-sentence. And they are not smaller — Moonshine tiny is 123MB of
ONNX once converted, against 45MB for the model in `zipformer-20m-en`. Whisper is
worse again, since it pads every input to a fixed 30 seconds of audio whatever
was actually said.

They are the right answer when transcript quality matters more than delay — they
are cased, punctuated and multilingual — which is the opposite trade to the one
being made here.

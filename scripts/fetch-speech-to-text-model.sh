#!/usr/bin/env bash
#
# Downloads the prebuilt sherpa-ncnn WebAssembly recogniser into
# public/speech-to-text/. Nothing here is built from source: the Hugging Face
# space below is a static space that already contains the emscripten output, so
# this only fetches four files and checks them against the hashes recorded at
# the pinned revision.
#
# The model is 141MB, which is why it is fetched rather than committed. Run this
# once after cloning; public/speech-to-text/.gitignore keeps the results out of
# git.

set -euo pipefail

REVISION=4901c6e472b4c99d104444f805ec93e671c48812
BASE="https://huggingface.co/spaces/k2-fsa/web-assembly-asr-sherpa-ncnn-en/resolve/$REVISION"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/public/speech-to-text"

# file:sha256, as published at $REVISION.
FILES=(
  "sherpa-ncnn.js:9d9a74dd6ea4174210b63ed75bf0be248e315cfa0569efa957e3a77f24acdd12"
  "sherpa-ncnn-wasm-main.js:bb8a60a40650f4d648bab677c16b4f5b8456156861dbd77201ff18cbbb328b2b"
  "sherpa-ncnn-wasm-main.wasm:43acc0c12a58b53b3164582009a175b829cca5c50a8db4b7907c9b48c44448ae"
  "sherpa-ncnn-wasm-main.data:6e8b17f3820d3bda13616a91cf6957056ff202674c9e749d890782ad4de317fb"
)

mkdir -p "$DEST"

for entry in "${FILES[@]}"; do
    name="${entry%%:*}"
    want="${entry##*:}"
    path="$DEST/$name"

    if [ -f "$path" ] && [ "$(sha256sum "$path" | cut -d' ' -f1)" = "$want" ]; then
        echo "$name is already up to date"
        continue
    fi

    echo "fetching $name"
    curl --fail --location --progress-bar --output "$path.part" "$BASE/$name"

    got="$(sha256sum "$path.part" | cut -d' ' -f1)"
    if [ "$got" != "$want" ]; then
        rm -f "$path.part"
        echo "$name did not match its recorded hash: expected $want, got $got" >&2
        exit 1
    fi
    mv "$path.part" "$path"
done

echo "speech-to-text model ready in $DEST"

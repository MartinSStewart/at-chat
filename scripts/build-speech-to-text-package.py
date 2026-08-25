#!/usr/bin/env python3
"""Repack an emscripten preload bundle around a different model.

The sherpa WebAssembly builds published on Hugging Face bake one model into a
`.data` file, and record where each file sits inside it as a JSON blob in the
emscripten glue JavaScript. Swapping the model therefore means rewriting both,
which is all this does: concatenate the new model files and patch the offsets.

Nothing is compiled. The `.wasm` is the recogniser and does not care which model
it loads, so the same binary serves every package built this way.

    build-speech-to-text-package.py --glue upstream/sherpa-ncnn-wasm-main.js \
                                    --model-dir models/foo \
                                    --out-dir public/speech-to-text/foo
"""

import argparse
import json
import pathlib
import re
import shutil
import sys

# The glue contains exactly one loadPackage call, holding the whole manifest.
# Older emscripten quotes the keys and newer emscripten does not, so both spellings
# have to be recognised; what gets written back is always quoted, which parses
# either way.
MANIFEST = re.compile(
    r'loadPackage\(\s*(\{\s*"?files"?\s*:\s*\[[^\]]*\]\s*,'
    r'\s*"?remote_package_size"?\s*:\s*\d+\s*\})\s*\)')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--glue", required=True, type=pathlib.Path,
                        help="emscripten glue .js published alongside the .wasm")
    parser.add_argument("--model-dir", required=True, type=pathlib.Path,
                        help="directory of model files to put in the package")
    parser.add_argument("--out-dir", required=True, type=pathlib.Path)
    parser.add_argument("--wasm", type=pathlib.Path,
                        help="copied next to the output, since the glue fetches it by name")
    args = parser.parse_args()

    glue = args.glue.read_text()
    match = MANIFEST.search(glue)
    if not match:
        sys.exit(f"{args.glue} has no loadPackage manifest; is it emscripten glue?")

    # The recogniser opens its model by name, so the names have to survive.
    # Sorted, because that is the order file_packager itself writes them in and
    # it keeps rebuilds byte-identical.
    sources = sorted(p for p in args.model_dir.iterdir() if p.is_file())
    if not sources:
        sys.exit(f"{args.model_dir} is empty")

    args.out_dir.mkdir(parents=True, exist_ok=True)
    data_path = args.out_dir / args.glue.name.replace(".js", ".data")

    files = []
    offset = 0
    with data_path.open("wb") as data:
        for source in sources:
            payload = source.read_bytes()
            data.write(payload)
            files.append({"filename": "/" + source.name,
                          "start": offset,
                          "end": offset + len(payload)})
            offset += len(payload)

    manifest = json.dumps({"files": files, "remote_package_size": offset},
                          separators=(",", ":"))
    (args.out_dir / args.glue.name).write_text(
        glue[:match.start(1)] + manifest + glue[match.end(1):])

    if args.wasm:
        shutil.copy(args.wasm, args.out_dir / args.wasm.name)

    print(f"{data_path} ({offset / 1e6:.1f} MB)")
    for entry in files:
        print(f"  {entry['end'] - entry['start']:>12,}  {entry['filename']}")


if __name__ == "__main__":
    main()

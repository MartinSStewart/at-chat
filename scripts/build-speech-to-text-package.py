#!/usr/bin/env python3
"""Pack model files into an emscripten preload bundle.

The `.data` file emscripten preloads from is a plain concatenation of the files
it contains; what says which bytes are which is a manifest, held in the
emscripten glue JavaScript. Swapping in a different model is therefore a matter
of rewriting both, which is all this does. Nothing is compiled: the `.wasm` is
the recogniser and does not care which model it loads.

The manifest is always written out as `files.json` as well, because
ncnn-recognizer.js loads the package without the glue and needs it on its own.
`--glue` additionally writes a patched copy of the glue, for the sherpa-onnx
package, which is still loaded the upstream way.

    build-speech-to-text-package.py --model-dir models/foo \
                                    --data-name sherpa-ncnn-wasm-main.data \
                                    --out-dir public/speech-to-text/models/foo
"""

import argparse
import json
import pathlib
import re
import shutil
import sys

# Older emscripten quotes the keys in the manifest and newer emscripten does not,
# so both spellings have to be recognised. What gets written back is always
# quoted, which parses either way.
MANIFEST = re.compile(
    r'loadPackage\(\s*(\{\s*"?files"?\s*:\s*\[[^\]]*\]\s*,'
    r'\s*"?remote_package_size"?\s*:\s*\d+\s*\})\s*\)')


def read_manifest(glue):
    """The manifest already inside a published glue file."""
    match = MANIFEST.search(glue.read_text())
    if not match:
        sys.exit(f"{glue} has no loadPackage manifest; is it emscripten glue?")
    # The unquoted form is not JSON, so let the keys be quoted before parsing.
    text = re.sub(r'([{,])\s*(files|filename|start|end|remote_package_size)\s*:', r'\1"\2":', match.group(1))
    return json.loads(text)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-dir", required=True, type=pathlib.Path,
                        help="directory of model files to put in the package")
    parser.add_argument("--data-name", required=True,
                        help="what the recogniser's loader fetches the package as")
    parser.add_argument("--out-dir", required=True, type=pathlib.Path)
    parser.add_argument("--glue", type=pathlib.Path,
                        help="emscripten glue to rewrite the manifest of, for packages loaded through it")
    parser.add_argument("--wasm", type=pathlib.Path,
                        help="copied next to the output, since the loader fetches it by name")
    args = parser.parse_args()

    # The recogniser opens its model by name, so the names have to survive.
    # Sorted, because that is the order file_packager itself writes them in and
    # it keeps rebuilds byte-identical.
    sources = sorted(p for p in args.model_dir.iterdir() if p.is_file())
    if not sources:
        sys.exit(f"{args.model_dir} is empty")

    args.out_dir.mkdir(parents=True, exist_ok=True)
    data_path = args.out_dir / args.data_name

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

    write_manifest(args.out_dir, {"files": files, "remote_package_size": offset}, args.glue)

    if args.wasm:
        shutil.copy(args.wasm, args.out_dir / args.wasm.name)

    print(f"{data_path} ({offset / 1e6:.1f} MB)")
    for entry in files:
        print(f"  {entry['end'] - entry['start']:>12,}  {entry['filename']}")


def write_manifest(out_dir, manifest, glue):
    (out_dir / "files.json").write_text(json.dumps(manifest, separators=(",", ":")))

    if glue:
        text = glue.read_text()
        match = MANIFEST.search(text)
        if not match:
            sys.exit(f"{glue} has no loadPackage manifest; is it emscripten glue?")
        (out_dir / glue.name).write_text(
            text[:match.start(1)]
            + json.dumps(manifest, separators=(",", ":"))
            + text[match.end(1):])


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Fetch the local speech-to-text models into public/speech-to-text/models/.

Every recogniser here is published prebuilt: the WebAssembly comes from a static
Hugging Face space or a sherpa-onnx GitHub release, and the models come from
Hugging Face. Nothing is compiled. Where a model is not the one its build shipped
with, build-speech-to-text-package.py repacks the emscripten bundle around it,
which is a matter of rewriting offsets rather than of building anything.

Everything is checked against a recorded sha256, so a bad download fails here
rather than as an unreadable model later.

    ./scripts/fetch-speech-to-text-models.py                  # all of them
    ./scripts/fetch-speech-to-text-models.py zipformer-20m-en # just one
"""

import hashlib
import importlib.util
import pathlib
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
MODELS = ROOT / "public" / "speech-to-text" / "models"
PACKAGER = ROOT / "scripts" / "build-speech-to-text-package.py"

# The sherpa-ncnn WebAssembly build, from a static space that contains the
# emscripten output rather than the sources. The English model is baked into the
# .data this space publishes, so that one model needs no repacking.
NCNN_SPACE = ("https://huggingface.co/spaces/k2-fsa/web-assembly-asr-sherpa-ncnn-en"
              "/resolve/4901c6e472b4c99d104444f805ec93e671c48812")
# Only the recogniser itself is kept. The 77KB of emscripten glue published
# beside it, and the 8KB wrapper over the C API, are both replaced by
# public/speech-to-text/ncnn-recognizer.js — except that the glue is still
# fetched, because the manifest saying where each model file sits inside the
# English package's .data is held inside it and nowhere else.
NCNN_ENGINE = {
    "sherpa-ncnn-wasm-main.wasm": "43acc0c12a58b53b3164582009a175b829cca5c50a8db4b7907c9b48c44448ae",
}
NCNN_ENGLISH_GLUE = ("sherpa-ncnn-wasm-main.js",
                     "bb8a60a40650f4d648bab677c16b4f5b8456156861dbd77201ff18cbbb328b2b")
NCNN_ENGLISH_DATA = ("sherpa-ncnn-wasm-main.data",
                     "6e8b17f3820d3bda13616a91cf6957056ff202674c9e749d890782ad4de317fb")

# The sherpa-onnx WebAssembly build, from the release the project's own workflow
# uploads. The archive is 175MB because it carries a model we throw away; only
# the recogniser and its glue are kept.
ONNX_RELEASE = ("https://github.com/k2-fsa/sherpa-onnx/releases/download/v1.13.6"
                "/sherpa-onnx-wasm-simd-v1.13.6-en-asr-zipformer.tar.bz2")
ONNX_RELEASE_SHA = "609d473f1ae060a9e25d82c88ca5abb87fdf1f43523920259aae2155a9cbc8b8"
ONNX_ENGINE = ["sherpa-onnx-asr.js", "sherpa-onnx-wasm-main-asr.js", "sherpa-onnx-wasm-main-asr.wasm"]

NCNN_SMALL = "https://huggingface.co/csukuangfj/sherpa-ncnn-streaming-zipformer-small-bilingual-zh-en-2023-02-16/resolve/main"
ONNX_20M = "https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17/resolve/main"

# Each model's files, as `saved name: (url, sha256)`. The saved names matter:
# the recogniser opens its model by name, and the int8 files are renamed to the
# plain names sherpa-onnx looks for by default.
MODEL_FILES = {
    "zipformer-small-zh-en": {
        name: (f"{NCNN_SMALL}/{name}", digest) for name, digest in {
            "decoder_jit_trace-pnnx.ncnn.bin": "4d1bb6ff7176907da2d19f451ba5ac13d72b56c675c8c41abd6e2f35e99bd435",
            "decoder_jit_trace-pnnx.ncnn.param": "cb88f5894978fd3e85369d2f8ea55621809fceb2b5158243fb0cd025eb4f1aaf",
            "encoder_jit_trace-pnnx.ncnn.bin": "0d3678d99dbb821d127511552c5c8451319a24469c5e5fbd9da1f7084254240f",
            "encoder_jit_trace-pnnx.ncnn.param": "8025162b7d5042a4b06f3794fcd6bda7533eec65ce50533df7d8b0d91ff70887",
            "joiner_jit_trace-pnnx.ncnn.bin": "2ee60ac939e61494ef3cacf2768e0d786ed7461e636664f078dd6829877b6377",
            "joiner_jit_trace-pnnx.ncnn.param": "75f733e68e479904181fdcf48a6a717b2b0fecbd364413e73bd44f25828922ce",
            "tokens.txt": "a8e0e4ec53810e433789b54a5c0134a7eaa2ffca595a6334d54c00da858841d3",
        }.items()
    },
    "zipformer-20m-en": {
        # The encoder and joiner are the int8 exports and the decoder is not,
        # which is how sherpa-onnx ships this model: the decoder is 2MB either
        # way, and quantising it buys nothing. int8 costs no measurable accuracy
        # here and halves the download.
        "encoder.onnx": (f"{ONNX_20M}/encoder-epoch-99-avg-1.int8.onnx",
                         "3810755ce7c3ab26b42a8bcf39d191308fa27fb0f53358823ba46141d03b7eb3"),
        "decoder.onnx": (f"{ONNX_20M}/decoder-epoch-99-avg-1.onnx",
                         "45a7f940ecfb53d89fa270ad11b88b961e53a317203eb24b1c8e95ed208b0f30"),
        "joiner.onnx": (f"{ONNX_20M}/joiner-epoch-99-avg-1.int8.onnx",
                        "e085d73b593cf9b0707f370dbd656d58327d3fe36d80d849202ef81df02cb01e"),
        "tokens.txt": (f"{ONNX_20M}/tokens.txt",
                       "49e3c2646595fd907228b3c6787069658f67b17377c60aeb8619c4551b2316fb"),
    },
}


def load_packager():
    """build-speech-to-text-package.py, whose name is not an importable one."""
    # Importing it would otherwise drop a .pyc into scripts/__pycache__.
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("packager", PACKAGER)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def digest_of(path):
    hasher = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            hasher.update(block)
    return hasher.hexdigest()


def download(url, path, want):
    if path.exists() and digest_of(path) == want:
        return path

    print(f"  fetching {path.name}")
    path.parent.mkdir(parents=True, exist_ok=True)
    part = path.with_suffix(path.suffix + ".part")
    with urllib.request.urlopen(url) as response, part.open("wb") as out:
        shutil.copyfileobj(response, out)

    got = digest_of(part)
    if got != want:
        part.unlink()
        sys.exit(f"{path.name} did not match its recorded hash: expected {want}, got {got}")
    part.rename(path)
    return path


def repack(model_dir, out_dir, data_name, wasm, glue=None):
    command = [sys.executable, str(PACKAGER),
               "--model-dir", str(model_dir), "--data-name", data_name,
               "--out-dir", str(out_dir), "--wasm", str(wasm)]
    if glue:
        command += ["--glue", str(glue)]
    subprocess.run(command, check=True)


def ncnn_engine(cache):
    for name, want in NCNN_ENGINE.items():
        download(f"{NCNN_SPACE}/{name}", cache / name, want)
    return cache


def onnx_engine(cache):
    if all((cache / name).exists() for name in ONNX_ENGINE):
        return cache

    archive = download(ONNX_RELEASE, cache / "sherpa-onnx-wasm.tar.bz2", ONNX_RELEASE_SHA)
    print("  unpacking the sherpa-onnx release")
    with tarfile.open(archive) as tar:
        for member in tar.getmembers():
            name = pathlib.Path(member.name).name
            if name in ONNX_ENGINE:
                source = tar.extractfile(member)
                (cache / name).write_bytes(source.read())
    # 175MB of it was a model we do not use.
    archive.unlink()
    return cache


def build_zipformer_en(cache):
    # The English model is the one the upstream package was built around, so its
    # .data is used exactly as published rather than repacked. Its manifest is
    # lifted out of the glue and written beside it, and the glue itself is then
    # not kept.
    engine = ncnn_engine(cache)
    out = MODELS / "zipformer-en"
    out.mkdir(parents=True, exist_ok=True)
    for name in NCNN_ENGINE:
        shutil.copy(engine / name, out / name)

    name, want = NCNN_ENGLISH_DATA
    download(f"{NCNN_SPACE}/{name}", out / name, want)

    name, want = NCNN_ENGLISH_GLUE
    glue = download(f"{NCNN_SPACE}/{name}", cache / name, want)
    packager = load_packager()
    packager.write_manifest(out, packager.read_manifest(glue), None)


def build_zipformer_small_zh_en(cache):
    engine = ncnn_engine(cache)
    model = cache / "zipformer-small-zh-en"
    for name, (url, want) in MODEL_FILES["zipformer-small-zh-en"].items():
        download(url, model / name, want)

    repack(model, MODELS / "zipformer-small-zh-en", "sherpa-ncnn-wasm-main.data",
           engine / "sherpa-ncnn-wasm-main.wasm")


def build_zipformer_20m_en(cache):
    engine = onnx_engine(cache)
    model = cache / "zipformer-20m-en"
    for name, (url, want) in MODEL_FILES["zipformer-20m-en"].items():
        download(url, model / name, want)

    out = MODELS / "zipformer-20m-en"
    repack(model, out, "sherpa-onnx-wasm-main-asr.data",
           engine / "sherpa-onnx-wasm-main-asr.wasm",
           glue=engine / "sherpa-onnx-wasm-main-asr.js")
    shutil.copy(engine / "sherpa-onnx-asr.js", out / "sherpa-onnx-asr.js")


BUILDERS = {
    "zipformer-20m-en": build_zipformer_20m_en,
    "zipformer-small-zh-en": build_zipformer_small_zh_en,
    "zipformer-en": build_zipformer_en,
}


def main():
    wanted = sys.argv[1:] or list(BUILDERS)
    unknown = [name for name in wanted if name not in BUILDERS]
    if unknown:
        sys.exit(f"unknown model(s): {', '.join(unknown)}\navailable: {', '.join(BUILDERS)}")

    # Kept between runs so that rebuilding one model, or adding another, does not
    # download the recogniser again.
    cache = pathlib.Path(tempfile.gettempdir()) / "at-chat-speech-to-text"
    cache.mkdir(parents=True, exist_ok=True)

    for name in wanted:
        print(name)
        BUILDERS[name](cache)

    print(f"\nmodels ready in {MODELS}")
    print(f"the downloads are cached in {cache}; delete it to reclaim the space")


if __name__ == "__main__":
    main()

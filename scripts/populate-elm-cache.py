#!/usr/bin/env python3
"""Populate the local Elm package cache from jsDelivr.

Why this exists
---------------
`lamdera make` / `elm make` download each package's *source* from GitHub
zipball URLs (e.g. https://github.com/elm/core/zipball/1.0.5/). In some
sandboxed environments the outbound egress policy only allows a specific
repo and blocks every other github.com request with:

    400 Bad Request  "Request path could not be canonicalized."
    403              "GitHub access to this repository is not enabled ..."

So dependency downloads fail and nothing compiles. The package *registry*
(package.elm-lang.org) is reachable, but the source zipballs on github.com
are not.

The fix: jsDelivr (cdn.jsdelivr.net) mirrors public GitHub repos file-by-file
and is not blocked. This script reads elm.json, and for every dependency that
is missing its `src/`, downloads the full file tree from jsDelivr into the
Elm cache. After running it, `lamdera make` compiles offline.

Notes
-----
* lamdera/* packages are NOT on GitHub. The lamdera compiler knows them without
  a cache entry, but elm-test-rs and elm-review solve dependencies themselves and
  need the sources on disk, so those come from static.lamdera.com instead.
* Safe to re-run: packages that already have a `src/` directory are skipped.
* Honors ELM_HOME (defaults to ~/.elm). Elm 0.19.1 layout is assumed.

Usage
-----
    python3 scripts/populate-elm-cache.py [elm.json ...]

With no arguments it populates the packages needed by elm.json, review/elm.json
and any manifest elm-review has generated under elm-stuff/, so `lamdera make`,
`elm-test-rs` and `elm-review` all work offline. The manifests disagree on a few
versions (e.g. elm-explorations/test), and every version named is cached.

It also repairs half-downloaded packages already in the cache — see stubs().
"""

import concurrent.futures
import glob
import hashlib
import io
import json
import os
import shutil
import sys
import urllib.request
import zipfile

ELM_HOME = os.environ.get("ELM_HOME") or os.path.expanduser("~/.elm")
PACKAGES = os.path.join(ELM_HOME, "0.19.1", "packages")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# elm-review solves its own dependencies rather than reusing review/elm.json, and
# writes the result into elm-stuff/ on its first run (its internal parser app pins
# e.g. elm/json 1.1.3, which neither of our manifests mention). Globbing these picks
# up whatever that solve chose, so nothing has to be hardcoded here.
GENERATED = os.path.join(ROOT, "elm-stuff", "generated-code", "**", "elm.json")

# elm-review keeps its own cache of each dependency's docs.json, separate from the
# compiler's package cache, and fills it from package.elm-lang.org. The directories
# below are versioned by elm-review and by Elm, so both are globbed rather than named.
REVIEW_DOCS = os.path.join(ELM_HOME, "elm-review", "*", "*", "packages")
REVIEW_RESULTS = os.path.join(
    ROOT, "elm-stuff", "generated-code", "jfmengels", "elm-review", "cli", "*", "result-cache"
)

# elm-test-rs compiles the test suite against its own runner package, which isn't a
# dependency in elm.json. Without it, `elm-test-rs --offline` fails with
# "there is no version of mpizenberg/elm-test-runner in 6.0.0".
EXTRA_PACKAGES = {("mpizenberg/elm-test-runner", "6.0.0")}


def default_elm_jsons():
    return [
        os.path.join(ROOT, "elm.json"),
        os.path.join(ROOT, "review", "elm.json"),
    ] + glob.glob(GENERATED, recursive=True)


def all_deps(elm_jsons):
    """Every (package, version) pair the given manifests need.

    A set of pairs rather than a {package: version} dict because elm.json and
    review/elm.json pin different versions of a few packages, and the cache
    needs both.
    """
    deps = set(EXTRA_PACKAGES)
    for path in elm_jsons:
        d = json.load(open(path))
        for section in ("dependencies", "test-dependencies"):
            for kind in ("direct", "indirect"):
                deps.update(d.get(section, {}).get(kind, {}).items())
    return deps


def fetch(url, timeout):
    # static.lamdera.com answers 403 to urllib's default "Python-urllib/3.x"
    # User-Agent, so every request sends one of our own.
    request = urllib.request.Request(url, headers={"User-Agent": "populate-elm-cache"})
    return urllib.request.urlopen(request, timeout=timeout)


def get_json(url):
    with fetch(url, 30) as r:
        return json.load(r)


def list_files(owner, repo, ver):
    url = f"https://data.jsdelivr.com/v1/packages/gh/{owner}/{repo}@{ver}?structure=flat"
    return [f["name"] for f in get_json(url).get("files", [])]


def download(owner, repo, ver, name):
    # jsDelivr paths can't contain spaces/control chars; skip those files
    # (they are never part of an Elm package's compiled source anyway).
    if any(c.isspace() for c in name):
        return None
    url = f"https://cdn.jsdelivr.net/gh/{owner}/{repo}@{ver}{name}"
    dest = os.path.join(PACKAGES, owner, repo, ver, name.lstrip("/"))
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    for attempt in range(3):
        try:
            with fetch(url, 60) as r:
                content = r.read()
            with open(dest, "wb") as f:
                f.write(content)
            return None
        except Exception as e:
            if attempt == 2:
                return f"{owner}/{repo}@{ver}{name}: {e}"


def download_lamdera(pkg, ver):
    """Fetch one lamdera/* package from static.lamdera.com into the cache.

    The compiler resolves these itself, so `lamdera make` is happy without them,
    but elm-test-rs and elm-review run their own dependency solve against the
    cache and fail outright when they are missing ("there is no version of
    lamdera/containers in 1.0.0"). Each package is published as an endpoint.json
    naming a zip and its sha1; the zip holds a single `<version>/` directory.
    """
    for attempt in range(3):
        try:
            endpoint = get_json(f"https://static.lamdera.com/r/{pkg}/{ver}/endpoint.json")
            with fetch(endpoint["url"], 60) as r:
                archive = r.read()
            break
        except Exception as e:
            if attempt == 2:
                return f"{pkg}@{ver}: {e}"

    digest = hashlib.sha1(archive).hexdigest()
    if digest != endpoint["hash"]:
        return f"{pkg}@{ver}: expected sha1 {endpoint['hash']}, got {digest}"

    # Extract to a scratch dir first so a failure part way through can't leave a
    # src-less stub behind, which is what stubs() has to clean up after.
    dest = os.path.join(PACKAGES, pkg, ver)
    staging = dest + ".partial"
    shutil.rmtree(staging, ignore_errors=True)
    zipfile.ZipFile(io.BytesIO(archive)).extractall(staging)
    shutil.rmtree(dest, ignore_errors=True)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    os.rename(os.path.join(staging, ver), dest)
    shutil.rmtree(staging, ignore_errors=True)
    return None


def mirror_lamdera_docs():
    """Copy the lamdera/* docs.json files into elm-review's package cache.

    package.elm-lang.org has never heard of the lamdera packages, so elm-review
    ends up with no docs for them. Without docs it can't tell that anything
    imports SeqDict or Effect.Command and reports lamdera/containers and
    lamdera/program-test as unused dependencies.
    """
    copied = 0
    for cache in glob.glob(REVIEW_DOCS):
        for docs in glob.glob(os.path.join(PACKAGES, "lamdera", "*", "*", "docs.json")):
            dest = os.path.join(cache, os.path.relpath(docs, PACKAGES))
            if os.path.exists(dest):
                continue
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            shutil.copyfile(docs, dest)
            copied += 1
    return copied


def stubs():
    """Packages the compiler started fetching but never finished.

    A blocked download leaves behind a directory holding just the package's
    elm.json, with no src/. The compiler treats that as "still needs fetching"
    and tries GitHub again on every build, so a stub is as fatal as a missing
    package — and it can name a version no manifest mentions.
    """
    found = set()
    for meta in glob.glob(os.path.join(PACKAGES, "*", "*", "*", "elm.json")):
        version_dir = os.path.dirname(meta)
        if os.path.isdir(os.path.join(version_dir, "src")):
            continue
        version = os.path.basename(version_dir)
        repo_dir = os.path.dirname(version_dir)
        pkg = os.path.basename(os.path.dirname(repo_dir)) + "/" + os.path.basename(repo_dir)
        found.add((pkg, version))
    return found


def main():
    elm_jsons = sys.argv[1:] or default_elm_jsons()

    todo, lamdera = [], []
    for pkg, ver in sorted(all_deps(elm_jsons) | stubs()):
        if os.path.isdir(os.path.join(PACKAGES, pkg, ver, "src")):
            continue  # already populated
        if pkg.startswith("lamdera/"):
            lamdera.append((pkg, ver))
        else:
            todo.append(pkg.split("/") + [ver])

    tasks, errors = [], []
    for owner, repo, ver in todo:
        try:
            for name in list_files(owner, repo, ver):
                tasks.append((owner, repo, ver, name))
        except Exception as e:
            errors.append(f"LIST {owner}/{repo}@{ver}: {e}")

    print(
        f"{len(todo) + len(lamdera)} packages, {len(tasks)} files -> {PACKAGES}",
        flush=True,
    )
    with concurrent.futures.ThreadPoolExecutor(max_workers=16) as ex:
        for e in ex.map(lambda t: download(*t), tasks):
            if e:
                errors.append(e)
        for e in ex.map(lambda t: download_lamdera(*t), lamdera):
            if e:
                errors.append(e)

    if mirror_lamdera_docs():
        # The verdicts elm-review reached while those docs were missing are cached
        # per review run and would otherwise outlive the fix, so drop them and let
        # the next run review with the full picture.
        for cache in glob.glob(REVIEW_RESULTS):
            shutil.rmtree(cache, ignore_errors=True)

    print(f"done ({len(errors)} errors)")
    for e in errors:
        print("  " + e)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

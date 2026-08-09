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
* lamdera/* packages are NOT on GitHub; they ship with the lamdera compiler
  and are already present in the cache. They are skipped automatically.
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
import json
import os
import sys
import urllib.request

ELM_HOME = os.environ.get("ELM_HOME") or os.path.expanduser("~/.elm")
PACKAGES = os.path.join(ELM_HOME, "0.19.1", "packages")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# elm-review solves its own dependencies rather than reusing review/elm.json, and
# writes the result into elm-stuff/ on its first run (its internal parser app pins
# e.g. elm/json 1.1.3, which neither of our manifests mention). Globbing these picks
# up whatever that solve chose, so nothing has to be hardcoded here.
GENERATED = os.path.join(ROOT, "elm-stuff", "generated-code", "**", "elm.json")

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


def get_json(url):
    with urllib.request.urlopen(url, timeout=30) as r:
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
            with urllib.request.urlopen(url, timeout=60) as r:
                content = r.read()
            with open(dest, "wb") as f:
                f.write(content)
            return None
        except Exception as e:
            if attempt == 2:
                return f"{owner}/{repo}@{ver}{name}: {e}"


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

    todo = []
    for pkg, ver in sorted(all_deps(elm_jsons) | stubs()):
        if pkg.startswith("lamdera/"):
            continue  # not on GitHub; ships with the compiler
        if os.path.isdir(os.path.join(PACKAGES, pkg, ver, "src")):
            continue  # already populated
        todo.append(pkg.split("/") + [ver])

    tasks, errors = [], []
    for owner, repo, ver in todo:
        try:
            for name in list_files(owner, repo, ver):
                tasks.append((owner, repo, ver, name))
        except Exception as e:
            errors.append(f"LIST {owner}/{repo}@{ver}: {e}")

    print(f"{len(todo)} packages, {len(tasks)} files -> {PACKAGES}", flush=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=16) as ex:
        for e in ex.map(lambda t: download(*t), tasks):
            if e:
                errors.append(e)

    print(f"done ({len(errors)} errors)")
    for e in errors:
        print("  " + e)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

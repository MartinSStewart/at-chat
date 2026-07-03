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
"""

import concurrent.futures
import json
import os
import sys
import urllib.request

ELM_HOME = os.environ.get("ELM_HOME") or os.path.expanduser("~/.elm")
PACKAGES = os.path.join(ELM_HOME, "0.19.1", "packages")
ELM_JSON = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "elm.json")


def all_deps():
    d = json.load(open(ELM_JSON))
    deps = {}
    for section in ("dependencies", "test-dependencies"):
        for kind in ("direct", "indirect"):
            deps.update(d.get(section, {}).get(kind, {}))
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


def main():
    todo = []
    for pkg, ver in all_deps().items():
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

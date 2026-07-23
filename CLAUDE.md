## Before starting
Install node modules

### If compilation fails to download dependencies (sandboxed environments)

In some sandboxed environments the egress policy only allows this one repo and
blocks all other github.com traffic. `lamdera make` downloads each dependency's
source from GitHub zipball URLs, so the first compile fails with errors like
`400 Bad Request "Request path could not be canonicalized."` or
`403 "GitHub access to this repository is not enabled ..."` for packages such as
`elm/core`. (The registry at package.elm-lang.org is reachable; only the github
source zipballs are blocked.)

Fix it once per environment by populating the Elm cache from jsDelivr (a GitHub
mirror that isn't blocked):
```
python3 scripts/populate-elm-cache.py
```
Then `npx lamdera make ...` works offline. The script is safe to re-run (it skips
packages already present) and skips `lamdera/*` packages, which ship with the
compiler.

## While coding

Run `npx lamdera make src/Frontend.elm src/Backend.elm` to check that the code compiles
Run `npx elm-format src/ --yes` to format the code

The following will run tests
```
npx elm-test-rs --compiler `which lamdera`
```

If `elm-test-rs` fails with "failed to fetch ... package.elm-lang.org" (happens in some sandboxed environments due to TLS interception), fall back to:
```
npx --yes elm-test --compiler=`which lamdera`
```

If `which lamdera` is empty (lamdera isn't on `PATH`, only available via `npx`),
pass the binary path directly:
```
npx --yes elm-test --compiler="$(realpath node_modules/.bin/lamdera)"
```

## Final notes
Ignore the overrides folder. It is only used when I want to modify lamdera/program-test.
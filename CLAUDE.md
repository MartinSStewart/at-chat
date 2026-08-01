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

If `elm-test-rs` fails with "failed to fetch ... package.elm-lang.org" (happens in some sandboxed environments due to
TLS interception), fall back to:

```
npx --yes elm-test --compiler=`which lamdera`
```

If `which lamdera` is empty (lamdera isn't on `PATH`, only available via `npx`),
pass the binary path directly:

```
npx --yes elm-test --compiler="$(realpath node_modules/.bin/lamdera)"
```

## Code style

### Prefer duplication over parameters when sharing code

When two functions are nearly the same, pull out only the part that is *identical* into a
helper that takes plain data. Leave the part that differs written out in both, even if that
repeats a few lines. Don't add a parameter to a shared helper just so both can call it.

A parameter that only exists to choose between behaviours makes every caller unreadable on
its own: you have to open the helper and substitute the argument back in before you know
what any of them draw.

```elm
-- Avoid. Neither view says what it renders without reading viewHelper first.
view : Mode -> Guild -> Element msg
view mode guild =
    viewHelper notificationView mode guild


discordView : Mode -> Guild -> Element msg
discordView mode guild =
    viewHelper discordNotificationView mode guild


viewHelper :
    (Int -> Int -> Ui.Color -> ChannelNotificationType -> Ui.Attribute msg)
    -> Mode
    -> Guild
    -> Element msg
viewHelper notificationAttribute mode guild =
    Ui.el [ notificationAttribute 0 -3 MyUi.background1 (notificationFor mode) ] (guildIcon guild mode)
```

```elm
-- Prefer. Each view reads top to bottom, and only the identical part is shared.
view : Mode -> Guild -> Element msg
view mode guild =
    Ui.el
        [ notificationView 0 -3 MyUi.background1 (notificationFor mode) ]
        (guildIcon guild mode)


discordView : Mode -> Guild -> Element msg
discordView mode guild =
    Ui.el
        [ discordNotificationView 0 -3 MyUi.background1 (notificationFor mode) ]
        (guildIcon guild mode)


guildIcon : Guild -> Mode -> Element msg
guildIcon guild mode =
    ...
```

`Bool` and config-record parameters that only switch behaviour are the same smell. This
isn't about higher order functions in general though: `List.map`, folds, decoders and event
handlers take functions because the caller genuinely supplies the logic.

## Final notes

* Ignore the overrides folder. It is only used when I want to modify lamdera/program-test.
* You don't need to warn me about type changes affecting Evergreen
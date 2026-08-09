## Before starting

Nothing — `.claude/hooks/session-start.sh` has already installed node modules and
filled the Elm package cache. If a compile ever fails saying it can't download a
package, run `python3 scripts/populate-elm-cache.py`; the comment at the top of that
script explains what it works around.

## While coding

`lamdera` is not on `PATH`, so anything taking a `--compiler` flag needs the path
spelled out. ``which lamdera`` returns nothing and silently breaks those commands.

Check that the code compiles:

```
npx lamdera make src/Frontend.elm src/Backend.elm
```

Format the code:

```
npx elm-format src/ --yes
```

Run the tests:

```
npx elm-test-rs --compiler "$(realpath node_modules/.bin/lamdera)"
```

Run elm-review and fix what it reports before you're done:

```
npx elm-review --compiler "$(realpath node_modules/.bin/lamdera)"
```

Compiling, formatting and passing tests isn't enough on its own — elm-review catches
unused code, redundant patterns and style rules that would otherwise need a cleanup
commit afterwards. `--fix-all` applies the mechanical fixes.

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
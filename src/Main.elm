module Main exposing (main)

import Browser
import Frontend
import Types exposing (FrontendModel, FrontendMsg)


{-| This file is used to measure approximate bundle size locally.

By importing `Frontend.app` we get all and only the code that is going to be included in the frontend.

This does not take into account the Lamdera harness, but that has a fixed size anyway.

To measure the size one could use something like:

`lamdera make src/Main.elm --output elm.js && npx elmjs-inspect elm.js | head && du -sh elm.js && npx uglify-js elm.js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' --output elm.compressed.js && npx uglify-js elm.compressed.js --mangle --output elm.min.js && du -sh elm.min.js && gzip -9 elm.min.js && du -sh elm.min.js.gz; rm elm.js elm.compressed.js elm.min.js.gz`

-}
main : Program {} FrontendModel FrontendMsg
main =
    Browser.application
        { init = \_ -> Frontend.app.init
        , view = Frontend.app.view
        , update = Frontend.app.update
        , subscriptions = Frontend.app.subscriptions
        , onUrlChange = Frontend.app.onUrlChange
        , onUrlRequest = Frontend.app.onUrlRequest
        }

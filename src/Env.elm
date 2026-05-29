module Env exposing (..)


domain : String
domain =
    if isProduction then
        "https://at-chat.app"

    else
        "http://localhost:8000"


isProduction_ : String
isProduction_ =
    "False"


isProduction : Bool
isProduction =
    isProduction_ == "True"


{-| Make sure this value is present in ./var/lib/atchat/secret.txt
-}
secretKey : String
secretKey =
    "123"


postmarkServerToken_ : String
postmarkServerToken_ =
    ""


slackClientId : String
slackClientId =
    "9460466681300.9470334175105"

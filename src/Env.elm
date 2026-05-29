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


{-| Cloudflare account tag (the account id, not the Realtime app id) used when querying the
GraphQL Analytics API to estimate how much Realtime egress is costing. Leave empty to disable
the Cloudflare cost check.
-}
cloudflareAccountId : String
cloudflareAccountId =
    ""


{-| Cloudflare API token with the "Account Analytics" read permission. Used to query monthly
Realtime egress usage. Leave empty to disable the Cloudflare cost check.
-}
cloudflareAnalyticsToken : String
cloudflareAnalyticsToken =
    ""

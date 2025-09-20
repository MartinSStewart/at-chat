module Env exposing (..)

import Discord
import EmailAddress exposing (EmailAddress)
import Postmark
import UInt64
import Unsafe


domain : String
domain =
    "http://localhost:8000"


isProduction_ : String
isProduction_ =
    "False"


isProduction : Bool
isProduction =
    isProduction_ == "True"


secretKey : String
secretKey =
    "123"


postmarkServerToken_ : String
postmarkServerToken_ =
    ""


postmarkServerToken : Postmark.ApiKey
postmarkServerToken =
    Postmark.apiKey postmarkServerToken_


noReplyEmailAddress : EmailAddress
noReplyEmailAddress =
    Unsafe.emailAddress "no-reply@at-chat.app"


adminEmail : String
adminEmail =
    "a@a.se"


openRouterKey : String
openRouterKey =
    ""


slackClientId : String
slackClientId =
    "9460466681300.9470334175105"


discordClientId_ : String
discordClientId_ =
    "1401255355928936478"


discordClientId : Discord.ClientId
discordClientId =
    UInt64.fromString discordClientId_ |> Maybe.withDefault UInt64.zero |> Discord.clientId

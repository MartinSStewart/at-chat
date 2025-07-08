module Env exposing (..)

import Discord exposing (Authentication)
import Discord.Id
import EmailAddress exposing (EmailAddress)
import Id exposing (DiscordUserId)
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


contactEmail : EmailAddress
contactEmail =
    Unsafe.emailAddress "help@email.com"


noReplyEmailAddress : EmailAddress
noReplyEmailAddress =
    Unsafe.emailAddress "no-reply@at-chat.app"


adminEmail : String
adminEmail =
    "a@a.se"


botToken_ : String
botToken_ =
    ""


botToken : Authentication
botToken =
    Discord.botToken botToken_


botId_ : String
botId_ =
    "842829883185037333"


botId : Discord.Id.Id DiscordUserId
botId =
    UInt64.fromString botId_ |> Maybe.withDefault UInt64.zero |> Discord.Id.fromUInt64

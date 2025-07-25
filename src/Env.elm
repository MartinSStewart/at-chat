module Env exposing (..)

import Discord exposing (Authentication)
import EmailAddress exposing (EmailAddress)
import Postmark
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


openRouterKey : String
openRouterKey =
    ""

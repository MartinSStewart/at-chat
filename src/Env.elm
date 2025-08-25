module Env exposing (..)

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


vapidPublicKey : String
vapidPublicKey =
    "BD_VrLjhb7FzVfqV7uGDBAl8X3YyGtAQu7VZRyCkLiSTO3Bm3hhWnNM6mg9Q7-YCHdGIFYN938UOHtmQksGwoFo"


vapidPrivateKey : String
vapidPrivateKey =
    "8k32wIygV7xXWed2zZ3aWTO23mJuDn9dvgh25f3zy5s"


openRouterKey : String
openRouterKey =
    ""

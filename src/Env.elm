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
    "BNz8vNFNoA1018dOyKch2Vm5eNK9W0Zzxf2SVJL7Hd1l-LgmX4QvrE587iH3TEEthM2xh1ftwrANWvuh48IbxCg"


vapidPrivateKey : String
vapidPrivateKey =
    "GfK4aiJoIsU36vFerEWeDEMmpJjLnMXP-XfA6XnjC7k"

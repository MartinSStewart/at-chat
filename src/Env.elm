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
    "123ABCabc"


{-| Whoever sends this in the `x-notify-token` header of `_r/notify-admins` can DM every admin
from the `notifyBotEmail` account. Left empty, the endpoint refuses everyone.
-}
notifyToken : String
notifyToken =
    ""


notifyBotEmail : String
notifyBotEmail =
    ""

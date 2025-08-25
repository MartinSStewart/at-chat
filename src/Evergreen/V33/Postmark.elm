module Evergreen.V33.Postmark exposing (..)

import Evergreen.V33.EmailAddress


type alias PostmarkSendResponse =
    { errorCode : Int
    , message : String
    , to : List Evergreen.V33.EmailAddress.EmailAddress
    }


type SendEmailError
    = UnknownError
        { statusCode : Int
        , body : String
        }
    | PostmarkError PostmarkSendResponse
    | NetworkError
    | Timeout
    | BadUrl String

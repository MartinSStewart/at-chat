module Evergreen.V179.Postmark exposing (..)

import Evergreen.V179.EmailAddress


type alias PostmarkSendResponse =
    { errorCode : Int
    , message : String
    , to : List Evergreen.V179.EmailAddress.EmailAddress
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

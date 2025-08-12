module Evergreen.V23.Postmark exposing (..)

import Evergreen.V23.EmailAddress


type alias PostmarkSendResponse =
    { errorCode : Int
    , message : String
    , to : List Evergreen.V23.EmailAddress.EmailAddress
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

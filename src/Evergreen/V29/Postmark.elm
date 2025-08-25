module Evergreen.V29.Postmark exposing (..)

import Evergreen.V29.EmailAddress


type alias PostmarkSendResponse =
    { errorCode : Int
    , message : String
    , to : List Evergreen.V29.EmailAddress.EmailAddress
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

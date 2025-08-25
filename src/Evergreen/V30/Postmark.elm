module Evergreen.V30.Postmark exposing (..)

import Evergreen.V30.EmailAddress


type alias PostmarkSendResponse =
    { errorCode : Int
    , message : String
    , to : List Evergreen.V30.EmailAddress.EmailAddress
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

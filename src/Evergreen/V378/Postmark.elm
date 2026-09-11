module Evergreen.V378.Postmark exposing (..)

import Evergreen.V378.EmailAddress


type ApiKey
    = ApiKey String


type alias PostmarkSendResponse =
    { errorCode : Int
    , message : String
    , to : List Evergreen.V378.EmailAddress.EmailAddress
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

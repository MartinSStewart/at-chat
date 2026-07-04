module Evergreen.V302.Postmark exposing (..)

import Evergreen.V302.EmailAddress


type ApiKey
    = ApiKey String


type alias PostmarkSendResponse =
    { errorCode : Int
    , message : String
    , to : List Evergreen.V302.EmailAddress.EmailAddress
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

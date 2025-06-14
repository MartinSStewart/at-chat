module Evergreen.V24.EmailAddress exposing (..)


type EmailAddress
    = EmailAddress
        { localPart : String
        , tags : List String
        , domain : String
        , tld : List String
        }

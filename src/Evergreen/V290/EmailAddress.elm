module Evergreen.V290.EmailAddress exposing (..)


type EmailAddress
    = EmailAddress
        { localPart : String
        , tags : List String
        , domain : String
        , tld : List String
        }

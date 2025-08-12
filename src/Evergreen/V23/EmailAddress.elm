module Evergreen.V23.EmailAddress exposing (..)


type EmailAddress
    = EmailAddress
        { localPart : String
        , tags : List String
        , domain : String
        , tld : List String
        }

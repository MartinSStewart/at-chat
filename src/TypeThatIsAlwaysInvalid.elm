module TypeThatIsAlwaysInvalid exposing (TypeThatIsAlwaysInvalid(..))

{-| A value of this type can be created and sent over the wire, but it can never
be decoded on the other end because `w3_validate_TypeThatIsAlwaysInvalid` always
fails. The admin page sends one to the backend so we can check that messages
failing wire validation get dropped before `updateFromFrontend` sees them.
-}


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


w3_validate_TypeThatIsAlwaysInvalid : TypeThatIsAlwaysInvalid -> Result String ()
w3_validate_TypeThatIsAlwaysInvalid _ =
    Err "TypeThatIsAlwaysInvalid is never valid"

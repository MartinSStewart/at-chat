module ChannelDescription exposing (ChannelDescription(..), empty, fromString, fromStringLossy, toString)

{-| -}


{-| OpaqueVariants
-}
type ChannelDescription
    = ChannelDescription String


maxLength : number
maxLength =
    500


fromString : String -> Result String ChannelDescription
fromString text =
    if String.length text > maxLength then
        Err ("Description can't be longer than " ++ String.fromInt maxLength ++ " characters")

    else
        Ok (ChannelDescription text)


fromStringLossy : String -> ChannelDescription
fromStringLossy text =
    ChannelDescription (String.left maxLength text)


empty : ChannelDescription
empty =
    ChannelDescription ""


toString : ChannelDescription -> String
toString (ChannelDescription a) =
    a

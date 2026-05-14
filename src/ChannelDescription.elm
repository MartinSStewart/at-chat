module ChannelDescription exposing (ChannelDescription(..), empty, fromStringLossy, toString)

{-| -}


{-| OpaqueVariants
-}
type ChannelDescription
    = ChannelDescription String


maxLength : number
maxLength =
    500


fromStringLossy : String -> ChannelDescription
fromStringLossy text =
    ChannelDescription (String.left maxLength text)


empty : ChannelDescription
empty =
    ChannelDescription ""


toString : ChannelDescription -> String
toString (ChannelDescription a) =
    a

module ChannelDescription exposing (ChannelDescription, empty, fromStringLossy)


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

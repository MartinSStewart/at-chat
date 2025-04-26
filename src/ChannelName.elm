module ChannelName exposing (ChannelName(..), fromString, toString, unknown)

import String.Nonempty exposing (NonemptyString)


type ChannelName
    = ChannelName NonemptyString


unknown : ChannelName
unknown =
    ChannelName (String.Nonempty.NonemptyString '<' "unknown>")


fromString : String -> Result String ChannelName
fromString text =
    case String.trim text |> String.Nonempty.fromString of
        Just nonempty ->
            if String.Nonempty.length nonempty > 50 then
                Err "Too long"

            else
                ChannelName nonempty |> Ok

        Nothing ->
            Err "Can't be empty"


toString : ChannelName -> String
toString (ChannelName a) =
    String.Nonempty.toString a

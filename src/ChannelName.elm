module ChannelName exposing (ChannelName(..), fromString, fromStringLossy, toString)

import String.Nonempty exposing (NonemptyString(..))


type ChannelName
    = ChannelName NonemptyString


maxLength : number
maxLength =
    50


fromString : String -> Result String ChannelName
fromString text =
    case String.trim text |> String.Nonempty.fromString of
        Just nonempty ->
            if String.Nonempty.length nonempty > maxLength then
                Err "Too long"

            else if String.Nonempty.any (\char -> char == '\n') nonempty then
                Err "Name can't contain line breaks"

            else
                ChannelName nonempty |> Ok

        Nothing ->
            Err "Can't be empty"


fromStringLossy : String -> ChannelName
fromStringLossy text =
    case
        String.trim text
            |> String.left maxLength
            |> String.filter (\char -> not (char == '\n' || char == '\u{000D}'))
            |> String.Nonempty.fromString
    of
        Just nonempty ->
            ChannelName nonempty

        Nothing ->
            ChannelName (NonemptyString 'e' "mpty")


toString : ChannelName -> String
toString (ChannelName a) =
    String.Nonempty.toString a

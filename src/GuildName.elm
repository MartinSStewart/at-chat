module GuildName exposing (GuildName(..), fromString, fromStringLossy, toString)

import String.Nonempty exposing (NonemptyString(..))


type GuildName
    = GuildName NonemptyString


maxLength : number
maxLength =
    100


fromString : String -> Result String GuildName
fromString text =
    case String.trim text |> String.Nonempty.fromString of
        Just nonempty ->
            if String.Nonempty.length nonempty > maxLength then
                Err "Too long"

            else if String.Nonempty.any (\char -> char == '\n') nonempty then
                Err "Name can't contain line breaks"

            else
                GuildName nonempty |> Ok

        Nothing ->
            Err "Can't be empty"


fromStringLossy : String -> GuildName
fromStringLossy text =
    case
        String.trim text
            |> String.left maxLength
            |> String.filter (\char -> not (char == '\n' || char == '\u{000D}'))
            |> String.Nonempty.fromString
    of
        Just nonempty ->
            GuildName nonempty

        Nothing ->
            GuildName (NonemptyString 'e' "mpty")


toString : GuildName -> String
toString (GuildName a) =
    String.Nonempty.toString a

module GuildName exposing (GuildName(..), fromString, toString)

import String.Nonempty exposing (NonemptyString)


type GuildName
    = GuildName NonemptyString


fromString : String -> Result String GuildName
fromString text =
    case String.trim text |> String.Nonempty.fromString of
        Just nonempty ->
            if String.Nonempty.length nonempty > 100 then
                Err "Too long"

            else if String.Nonempty.any (\char -> char == '\n') nonempty then
                Err "Name can't contain line breaks"

            else
                GuildName nonempty |> Ok

        Nothing ->
            Err "Can't be empty"


toString : GuildName -> String
toString (GuildName a) =
    String.Nonempty.toString a

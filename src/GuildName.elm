module GuildName exposing (GuildName(..), fromString, toString, unknown)

import String.Nonempty exposing (NonemptyString)


type GuildName
    = GuildName NonemptyString


unknown : GuildName
unknown =
    GuildName (String.Nonempty.NonemptyString '<' "unknown>")


fromString : String -> Result String GuildName
fromString text =
    case String.trim text |> String.Nonempty.fromString of
        Just nonempty ->
            if String.Nonempty.length nonempty > 100 then
                Err "Too long"

            else
                GuildName nonempty |> Ok

        Nothing ->
            Err "Can't be empty"


toString : GuildName -> String
toString (GuildName a) =
    String.Nonempty.toString a

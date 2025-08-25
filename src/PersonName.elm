module PersonName exposing (PersonName(..), fromString, fromStringLossy, toString)

import String.Nonempty exposing (NonemptyString(..))


type PersonName
    = PersonName NonemptyString


fromString : String -> Result String PersonName
fromString text =
    case String.trim text |> String.Nonempty.fromString of
        Just nonempty ->
            if String.Nonempty.length nonempty > 32 then
                Err "Too long"

            else if String.Nonempty.any (\char -> char == '\n' || char == '\u{000D}') nonempty then
                Err "Name can't contain line breaks"

            else
                PersonName nonempty |> Ok

        Nothing ->
            Err "Can't be empty"


fromStringLossy : String -> PersonName
fromStringLossy text =
    case
        String.trim text
            |> String.left 32
            |> String.filter (\char -> not (char == '\n' || char == '\u{000D}'))
            |> String.Nonempty.fromString
    of
        Just nonempty ->
            PersonName nonempty

        Nothing ->
            PersonName (NonemptyString 'e' "mpty")


toString : PersonName -> String
toString (PersonName a) =
    String.Nonempty.toString a

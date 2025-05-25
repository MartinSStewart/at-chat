module PersonName exposing (PersonName(..), fromString, toString)

import String.Nonempty exposing (NonemptyString)


type PersonName
    = PersonName NonemptyString


fromString : String -> Result String PersonName
fromString text =
    case String.trim text |> String.Nonempty.fromString of
        Just nonempty ->
            if String.Nonempty.length nonempty > 100 then
                Err "Too long"

            else if String.Nonempty.any (\char -> char == '\n') nonempty then
                Err "Name can't contain line breaks"

            else
                PersonName nonempty |> Ok

        Nothing ->
            Err "Can't be empty"


toString : PersonName -> String
toString (PersonName a) =
    String.Nonempty.toString a

module PersonName exposing (PersonName(..), fromString, toString, unknown)

import String.Nonempty exposing (NonemptyString)


type PersonName
    = PersonName NonemptyString


unknown : PersonName
unknown =
    PersonName (String.Nonempty.NonemptyString '<' "unknown>")


fromString : String -> Result String PersonName
fromString text =
    case String.trim text |> String.Nonempty.fromString of
        Just nonempty ->
            if String.Nonempty.length nonempty > 100 then
                Err "Too long"

            else
                PersonName nonempty |> Ok

        Nothing ->
            Err "Can't be empty"


toString : PersonName -> String
toString (PersonName a) =
    String.Nonempty.toString a

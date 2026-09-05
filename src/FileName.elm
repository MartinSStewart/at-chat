module FileName exposing (FileName(..), codec, fromString, toString)

import Serialize
import String.Nonempty exposing (NonemptyString(..))


type FileName
    = FileName NonemptyString


fromString : String -> FileName
fromString text =
    case
        String.trim text
            |> String.left 1024
            |> String.filter (\char -> char /= '\n' && char /= '\u{000D}' && char /= '/' && char /= '\\')
            |> String.Nonempty.fromString
    of
        Just nonempty ->
            FileName nonempty

        Nothing ->
            FileName (NonemptyString 'f' "ile")


toString : FileName -> String
toString (FileName a) =
    String.Nonempty.toString a


codec : Serialize.Codec e FileName
codec =
    Serialize.map fromString toString Serialize.string

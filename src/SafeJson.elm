module SafeJson exposing (SafeJson(..), decoder, encoder, toString)

import Dict exposing (Dict)
import Json.Decode
import Json.Encode
import SafeFloat exposing (SafeFloat)


type SafeJson
    = JsonString String
    | JsonNumber SafeFloat
    | JsonBool Bool
    | JsonObject (Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull


decoder : Json.Decode.Decoder SafeJson
decoder =
    Json.Decode.oneOf
        [ Json.Decode.map JsonString Json.Decode.string
        , Json.Decode.map JsonNumber SafeFloat.decode
        , Json.Decode.map JsonBool Json.Decode.bool
        , Json.Decode.map JsonObject (Json.Decode.dict (Json.Decode.lazy (\() -> decoder)))
        , Json.Decode.map JsonArray (Json.Decode.list (Json.Decode.lazy (\() -> decoder)))
        , Json.Decode.succeed JsonNull
        ]


encoder : SafeJson -> Json.Encode.Value
encoder safeJson =
    case safeJson of
        JsonString text ->
            Json.Encode.string text

        JsonNumber float ->
            SafeFloat.encode float

        JsonBool bool ->
            Json.Encode.bool bool

        JsonObject dict ->
            Dict.toList dict
                |> List.map (\( key, value ) -> ( key, encoder value ))
                |> Json.Encode.object

        JsonArray safeJsons ->
            Json.Encode.list encoder safeJsons

        JsonNull ->
            Json.Encode.null


toString : Int -> SafeJson -> String
toString indentation json =
    encoder json |> Json.Encode.encode indentation

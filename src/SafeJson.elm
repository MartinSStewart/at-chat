module SafeJson exposing (SafeJson(..), codec, decoder, encoder, toString)

import Codec exposing (Codec)
import Dict exposing (Dict)
import Json.Decode
import Json.Encode


type SafeJson
    = JsonString String
    | JsonNumber Float
    | JsonBool Bool
    | JsonObject (Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull


decoder : Json.Decode.Decoder SafeJson
decoder =
    Json.Decode.oneOf
        [ Json.Decode.map JsonString Json.Decode.string
        , Json.Decode.map JsonNumber Json.Decode.float
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
            Json.Encode.float float

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


codec : Codec SafeJson
codec =
    Codec.build encoder decoder

module SafeFloat exposing (SafeFloat, codec, decode, encode, fromFloat, serializeCodec, toString)

import Codec exposing (Codec)
import Json.Decode
import Json.Encode
import Serialize


type SafeFloat
    = SafeFloat Float


fromFloat : Float -> Result String SafeFloat
fromFloat float =
    if isNaN float || isInfinite float then
        Err ("Invalid SafeFloat: " ++ String.fromFloat float)

    else
        Ok (SafeFloat float)


w3_validate_SafeFloat : SafeFloat -> Result String ()
w3_validate_SafeFloat (SafeFloat value) =
    fromFloat value |> Result.map (\_ -> ())


toFloat : SafeFloat -> Float
toFloat (SafeFloat a) =
    a


toString : SafeFloat -> String
toString (SafeFloat a) =
    String.fromFloat a


decode : Json.Decode.Decoder SafeFloat
decode =
    Json.Decode.andThen
        (\a ->
            case fromFloat a of
                Ok safe ->
                    Json.Decode.succeed safe

                Err error ->
                    Json.Decode.fail error
        )
        Json.Decode.float


encode : SafeFloat -> Json.Encode.Value
encode value =
    Json.Encode.float (toFloat value)


codec : Codec SafeFloat
codec =
    Codec.build encode decode


serializeCodec : Serialize.Codec String SafeFloat
serializeCodec =
    Serialize.mapValid fromFloat toFloat Serialize.float

module WireHelper exposing (decodeBackendModel, encodeBackendModel)

{-| These functions are in a separate module because Intellij flags w3\_\* functions as missing and that's annoying to look at while doing other stuff.
-}

import Bytes.Decode exposing (Decoder)
import Bytes.Encode exposing (Encoder)
import Types exposing (BackendModel)


encodeBackendModel : BackendModel -> Encoder
encodeBackendModel =
    Types.w3_encode_BackendModel


decodeBackendModel : Decoder BackendModel
decodeBackendModel =
    Types.w3_decode_BackendModel

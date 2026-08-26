module Encryption exposing (..)

import Base64
import Bytes exposing (Bytes)
import Effect.Task exposing (Task)
import Json.Encode
import Serialize


type EncryptedData a
    = EncryptedData Bytes


type PublicKey
    = PublicKey Bytes


type PrivateKey
    = PrivateKey Bytes


encrypt : PublicKey -> Serialize.Codec e a -> a -> Task r x (EncryptedData a)
encrypt publicKey codec value =
    Debug.todo ""


decrypt : PrivateKey -> Serialize.Codec e a -> Bytes -> Task r (Serialize.Error e) a
decrypt privateKey codec bytes =
    Debug.todo ""


encode : EncryptedData a -> Json.Encode.Value
encode (EncryptedData bytes) =
    Base64.fromBytes bytes |> Maybe.withDefault "" |> Json.Encode.string

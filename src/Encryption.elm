port module Encryption exposing
    ( BytesHash
    , EncryptedData(..)
    , FromJs(..)
    , ToJs(..)
    , decryptMessage
    , encode
    , encryptMessage
    , fromJs
    , storeSharedSecret
    , toBase64
    )

{-| The symmetric half of end-to-end encrypted DMs, which lives in the browser rather
than in Elm.

The key agreement is pure Elm (see `X25519`) so that the handshake can be tested end to
end. Everything after it goes through here instead, for two reasons. Encrypting a large
file attachment in Elm would take seconds where the browser's AES does it in
milliseconds, and a `CryptoKey` the browser refuses to export cannot be read back out by
any script on the page, which a key sitting in the Elm model plainly can be.

The shared secret goes over to JS once, when a conversation is first encrypted. From then
on the key lives in IndexedDB and only ever comes back out as a `CryptoKey` handle, so
the plaintext of a message is the only secret that crosses the port after that.

-}

import Base64
import Bytes exposing (Bytes)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Id exposing (Id, UserId, Viewing_DmId)
import Json.Encode
import Serialize


{-| OpaqueVariants.
-}
type EncryptedData a
    = EncryptedData BytesHash Bytes


type BytesHash
    = BytesHash Int


encode : EncryptedData a -> Json.Encode.Value
encode data =
    Json.Encode.string (toBase64 data)


toBase64 : EncryptedData a -> String
toBase64 (EncryptedData _ bytes) =
    Base64.fromBytes bytes |> Maybe.withDefault ""



-- PORTS


type ToJs data
    = ToJs_StoreSharedSecret { otherUserId : Id UserId, sharedSecret : Bytes }
    | ToJs_EncryptMessage { requestId : Int, otherUserId : Id UserId, data : data }
    | ToJs_DecryptMessage { requestId : Int, otherUserId : Id UserId, data : Bytes }


storeSharedSecret : Id UserId -> Bytes -> Command FrontendOnly toMsg msg
storeSharedSecret otherUserId sharedSecret =
    Serialize.encodeToBytes
        (toJsCodec Serialize.unit)
        (ToJs_StoreSharedSecret { otherUserId = otherUserId, sharedSecret = sharedSecret })
        |> Command.sendToJsBytes "encryption_to_js" encryption_to_js


encryptMessage : Int -> Viewing_DmId -> Serialize.Codec e a -> a -> Command FrontendOnly toMsg msg
encryptMessage requestId id dataCodec data =
    Serialize.encodeToBytes
        (toJsCodec dataCodec)
        (ToJs_EncryptMessage { requestId = requestId, otherUserId = id.otherUserId, data = data })
        |> Command.sendToJsBytes "encryption_to_js" encryption_to_js


decryptMessage : Int -> Viewing_DmId -> Bytes -> Command FrontendOnly toMsg msg
decryptMessage requestId id data =
    Serialize.encodeToBytes
        (toJsCodec Serialize.unit)
        (ToJs_DecryptMessage { requestId = requestId, otherUserId = id.otherUserId, data = data })
        |> Command.sendToJsBytes "encryption_to_js" encryption_to_js


toJsCodec : Serialize.Codec e data -> Serialize.Codec e (ToJs data)
toJsCodec dataCodec =
    Serialize.customType
        (\a b c value ->
            case value of
                ToJs_StoreSharedSecret argA ->
                    a argA

                ToJs_EncryptMessage argA ->
                    b argA

                ToJs_DecryptMessage argA ->
                    c argA
        )
        |> Serialize.variant1
            ToJs_StoreSharedSecret
            (Serialize.record (\otherUserId sharedSecret -> { otherUserId = otherUserId, sharedSecret = sharedSecret })
                |> Serialize.field .otherUserId Id.codec
                |> Serialize.field .sharedSecret Serialize.bytes
                |> Serialize.finishRecord
            )
        |> Serialize.variant1
            ToJs_EncryptMessage
            (Serialize.record
                (\requestId otherUserId data -> { requestId = requestId, otherUserId = otherUserId, data = data })
                |> Serialize.field .requestId Serialize.int
                |> Serialize.field .otherUserId Id.codec
                |> Serialize.field .data dataCodec
                |> Serialize.finishRecord
            )
        |> Serialize.variant1
            ToJs_DecryptMessage
            (Serialize.record
                (\requestId otherUserId data -> { requestId = requestId, otherUserId = otherUserId, data = data })
                |> Serialize.field .requestId Serialize.int
                |> Serialize.field .otherUserId Id.codec
                |> Serialize.field .data Serialize.bytes
                |> Serialize.finishRecord
            )
        |> Serialize.finishCustomType


type FromJs a
    = FromJs_SharedSecretStored (Id UserId)
    | FromJs_SharedSecretFailed (Id UserId) String
    | FromJs_MessageEncrypted Int BytesHash (EncryptedData a)
    | FromJs_MessageEncryptFailed Int String


port encryption_to_js : Bytes -> Cmd msg


port encryption_from_js : (Bytes -> msg) -> Sub msg


fromJs : (Result String (FromJs a) -> msg) -> Subscription FrontendOnly msg
fromJs msg =
    Subscription.fromJsBytes
        "encryption_from_js"
        encryption_from_js
        (\bytes ->
            case Serialize.decodeFromBytes fromJsCodec bytes of
                Ok fromJs_ ->
                    msg (Ok fromJs_)

                Err _ ->
                    msg (Err "The browser sent back something this app can't read")
        )


fromJsCodec : Serialize.Codec e (FromJs a)
fromJsCodec =
    Serialize.customType
        (\fromJs_SharedSecretStoredEncoder fromJs_SharedSecretFailedEncoder fromJs_MessageEncryptedEncoder fromJs_MessageEncryptFailedEncoder value ->
            case value of
                FromJs_SharedSecretStored argA ->
                    fromJs_SharedSecretStoredEncoder argA

                FromJs_SharedSecretFailed argA argB ->
                    fromJs_SharedSecretFailedEncoder argA argB

                FromJs_MessageEncrypted argA argB argC ->
                    fromJs_MessageEncryptedEncoder argA argB argC

                FromJs_MessageEncryptFailed argA argB ->
                    fromJs_MessageEncryptFailedEncoder argA argB
        )
        |> Serialize.variant1 FromJs_SharedSecretStored Id.codec
        |> Serialize.variant2 FromJs_SharedSecretFailed Id.codec Serialize.string
        |> Serialize.variant3 FromJs_MessageEncrypted Serialize.int bytesHashCodec encryptedDataCodec
        |> Serialize.variant2 FromJs_MessageEncryptFailed Serialize.int Serialize.string
        |> Serialize.finishCustomType


encryptedDataCodec : Serialize.Codec e (EncryptedData a)
encryptedDataCodec =
    Serialize.map
        (\( a, b ) -> EncryptedData a b)
        (\(EncryptedData a b) -> ( a, b ))
        (Serialize.tuple bytesHashCodec Serialize.bytes)


bytesHashCodec : Serialize.Codec e BytesHash
bytesHashCodec =
    Serialize.map BytesHash (\(BytesHash a) -> a) Serialize.int

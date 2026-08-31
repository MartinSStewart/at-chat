port module Encryption exposing
    ( BytesHash(..)
    , DecryptManyRequestId
    , DecryptRequestId
    , EncryptManyRequestId
    , EncryptRequestId
    , EncryptedData(..)
    , FromJs(..)
    , ToJs(..)
    , decryptManyMessages
    , decryptMessage
    , encode
    , encryptManyMessages
    , encryptMessage
    , encryptedData
    , fromJs
    , fromJsCodec
    , hash
    , storeSharedSecret
    , toBase64
    , toJsCodec
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
import Bytes.Decode
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Id exposing (Id, UserId, Viewing_DmId)
import Json.Encode
import Serialize


{-| OpaqueVariants.
-}
type EncryptedData a
    = EncryptedData BytesHash Bytes


{-| OpaqueVariants.
-}
type BytesHash
    = BytesHash Int


type EncryptRequestId
    = EncryptRequestId Never


type DecryptRequestId
    = DecryptRequestId Never


type DecryptManyRequestId
    = DecryptManyRequestId Never


type EncryptManyRequestId
    = EncryptManyRequestId Never


encode : EncryptedData a -> Json.Encode.Value
encode data =
    Json.Encode.string (toBase64 data)


toBase64 : EncryptedData a -> String
toBase64 (EncryptedData _ bytes) =
    Base64.fromBytes bytes |> Maybe.withDefault ""


hash : EncryptedData a -> BytesHash
hash (EncryptedData hash2 _) =
    hash2


{-| Ciphertext starts with the random 12 byte IV that AES-GCM was given, and reusing an IV
with the same key breaks GCM outright, so those bytes are already the one thing about a
message that is guaranteed not to repeat. The first six of them are the number a message
is filed under.
-}
encryptedData : Bytes -> EncryptedData a
encryptedData bytes =
    EncryptedData (bytesHash bytes) bytes


bytesHash : Bytes -> BytesHash
bytesHash bytes =
    Bytes.Decode.decode
        (Bytes.Decode.map2
            (\high low -> BytesHash (high * 4294967296 + low))
            (Bytes.Decode.unsignedInt16 Bytes.BE)
            (Bytes.Decode.unsignedInt32 Bytes.BE)
        )
        bytes
        |> Maybe.withDefault (BytesHash 0)



-- PORTS


type ToJs data
    = ToJs_StoreSharedSecret { otherUserId : Id UserId, sharedSecret : Bytes }
    | ToJs_EncryptNewMessage { requestId : Id EncryptRequestId, otherUserId : Id UserId, data : data }
    | ToJs_DecryptNewMessage { requestId : Id DecryptRequestId, otherUserId : Id UserId, data : Bytes }
    | ToJs_DecryptManyMessages { requestId : Id DecryptManyRequestId, otherUserId : Id UserId, data : List Bytes }
    | ToJs_EncryptManyMessages { requestId : Id EncryptManyRequestId, otherUserId : Id UserId, data : List Bytes }


storeSharedSecret : Id UserId -> Bytes -> Command FrontendOnly toMsg msg
storeSharedSecret otherUserId sharedSecret =
    Serialize.encodeToBytes
        (toJsCodec Serialize.unit)
        (ToJs_StoreSharedSecret { otherUserId = otherUserId, sharedSecret = sharedSecret })
        |> Command.sendToJsBytes "encryption_to_js" encryption_to_js


encryptMessage : Id EncryptRequestId -> Viewing_DmId -> Serialize.Codec e a -> a -> Command FrontendOnly toMsg msg
encryptMessage requestId id dataCodec data =
    Serialize.encodeToBytes
        (toJsCodec dataCodec)
        (ToJs_EncryptNewMessage { requestId = requestId, otherUserId = id.otherUserId, data = data })
        |> Command.sendToJsBytes "encryption_to_js" encryption_to_js


decryptMessage : Id DecryptRequestId -> Viewing_DmId -> EncryptedData a -> Command FrontendOnly toMsg msg
decryptMessage requestId id (EncryptedData _ data) =
    Serialize.encodeToBytes
        (toJsCodec Serialize.unit)
        (ToJs_DecryptNewMessage { requestId = requestId, otherUserId = id.otherUserId, data = data })
        |> Command.sendToJsBytes "encryption_to_js" encryption_to_js


encryptManyMessages :
    Id EncryptManyRequestId
    -> Viewing_DmId
    -> Serialize.Codec e a
    -> List a
    -> Command FrontendOnly toMsg msg
encryptManyMessages requestId id dataCodec messages =
    Serialize.encodeToBytes
        (toJsCodec Serialize.unit)
        (ToJs_EncryptManyMessages
            { requestId = requestId
            , otherUserId = id.otherUserId
            , data = List.map (Serialize.encodeToBytes dataCodec) messages
            }
        )
        |> Command.sendToJsBytes "encryption_to_js" encryption_to_js


decryptManyMessages : Id DecryptManyRequestId -> Viewing_DmId -> List (EncryptedData a) -> Command FrontendOnly toMsg msg
decryptManyMessages requestId id messages =
    Serialize.encodeToBytes
        (toJsCodec Serialize.unit)
        (ToJs_DecryptManyMessages
            { requestId = requestId
            , otherUserId = id.otherUserId
            , data = List.map (\(EncryptedData _ bytes) -> bytes) messages
            }
        )
        |> Command.sendToJsBytes "encryption_to_js" encryption_to_js


toJsCodec : Serialize.Codec e data -> Serialize.Codec e (ToJs data)
toJsCodec dataCodec =
    Serialize.customType
        (\a b c d e value ->
            case value of
                ToJs_StoreSharedSecret argA ->
                    a argA

                ToJs_EncryptNewMessage argA ->
                    b argA

                ToJs_DecryptNewMessage argA ->
                    c argA

                ToJs_DecryptManyMessages argA ->
                    d argA

                ToJs_EncryptManyMessages argA ->
                    e argA
        )
        |> Serialize.variant1
            ToJs_StoreSharedSecret
            (Serialize.record (\otherUserId sharedSecret -> { otherUserId = otherUserId, sharedSecret = sharedSecret })
                |> Serialize.field .otherUserId Id.codec
                |> Serialize.field .sharedSecret Serialize.bytes
                |> Serialize.finishRecord
            )
        |> Serialize.variant1
            ToJs_EncryptNewMessage
            (Serialize.record
                (\requestId otherUserId data -> { requestId = requestId, otherUserId = otherUserId, data = data })
                |> Serialize.field .requestId Id.codec
                |> Serialize.field .otherUserId Id.codec
                |> Serialize.field .data dataCodec
                |> Serialize.finishRecord
            )
        |> Serialize.variant1
            ToJs_DecryptNewMessage
            (Serialize.record
                (\requestId otherUserId data -> { requestId = requestId, otherUserId = otherUserId, data = data })
                |> Serialize.field .requestId Id.codec
                |> Serialize.field .otherUserId Id.codec
                |> Serialize.field .data Serialize.bytes
                |> Serialize.finishRecord
            )
        |> Serialize.variant1
            ToJs_DecryptManyMessages
            (Serialize.record
                (\requestId otherUserId data -> { requestId = requestId, otherUserId = otherUserId, data = data })
                |> Serialize.field .requestId Id.codec
                |> Serialize.field .otherUserId Id.codec
                |> Serialize.field .data (Serialize.list Serialize.bytes)
                |> Serialize.finishRecord
            )
        |> Serialize.variant1
            ToJs_EncryptManyMessages
            (Serialize.record
                (\requestId otherUserId data -> { requestId = requestId, otherUserId = otherUserId, data = data })
                |> Serialize.field .requestId Id.codec
                |> Serialize.field .otherUserId Id.codec
                |> Serialize.field .data (Serialize.list Serialize.bytes)
                |> Serialize.finishRecord
            )
        |> Serialize.finishCustomType


type FromJs a
    = FromJs_SharedSecretStored (Id UserId)
    | FromJs_SharedSecretFailed (Id UserId) String
    | FromJs_NewMessageEncrypted (Id EncryptRequestId) (EncryptedData a)
    | FromJs_NewMessageEncryptFailed (Id EncryptRequestId) String
    | FromJs_NewMessageDecrypted (Id DecryptRequestId) a
    | FromJs_NewMessageDecryptFailed (Id DecryptRequestId)
    | FromJs_ManyMessagesDecrypted (Id DecryptManyRequestId) (List (Result () a))
    | FromJs_ManyMessagesEncrypted (Id EncryptManyRequestId) (List (EncryptedData a))
    | FromJs_ManyMessagesEncryptFailed (Id EncryptManyRequestId) String


port encryption_to_js : Bytes -> Cmd msg


port encryption_from_js : (Bytes -> msg) -> Sub msg


fromJs : Serialize.Codec e a -> (Result String (FromJs a) -> msg) -> Subscription FrontendOnly msg
fromJs aCodec msg =
    Subscription.fromJsBytes
        "encryption_from_js"
        encryption_from_js
        (\bytes ->
            case Serialize.decodeFromBytes (fromJsCodec aCodec) bytes of
                Ok fromJs_ ->
                    msg (Ok fromJs_)

                Err _ ->
                    msg (Err "The browser sent back something this app can't read")
        )


fromJsCodec : Serialize.Codec e a -> Serialize.Codec e (FromJs a)
fromJsCodec aCodec =
    Serialize.customType
        (\a b c d e f g h i value ->
            case value of
                FromJs_SharedSecretStored argA ->
                    a argA

                FromJs_SharedSecretFailed argA argB ->
                    b argA argB

                FromJs_NewMessageEncrypted argA argB ->
                    c argA argB

                FromJs_NewMessageEncryptFailed argA argB ->
                    d argA argB

                FromJs_NewMessageDecrypted argA argB ->
                    e argA argB

                FromJs_NewMessageDecryptFailed argA ->
                    f argA

                FromJs_ManyMessagesDecrypted argA argB ->
                    g argA argB

                FromJs_ManyMessagesEncrypted argA argB ->
                    h argA argB

                FromJs_ManyMessagesEncryptFailed argA argB ->
                    i argA argB
        )
        |> Serialize.variant1 FromJs_SharedSecretStored Id.codec
        |> Serialize.variant2 FromJs_SharedSecretFailed Id.codec Serialize.string
        |> Serialize.variant2 FromJs_NewMessageEncrypted Id.codec encryptedDataCodec
        |> Serialize.variant2 FromJs_NewMessageEncryptFailed Id.codec Serialize.string
        |> Serialize.variant2 FromJs_NewMessageDecrypted Id.codec aCodec
        |> Serialize.variant1 FromJs_NewMessageDecryptFailed Id.codec
        |> Serialize.variant2
            FromJs_ManyMessagesDecrypted
            Id.codec
            (Serialize.list (Serialize.result Serialize.unit aCodec))
        |> Serialize.variant2 FromJs_ManyMessagesEncrypted Id.codec (Serialize.list encryptedDataCodec)
        |> Serialize.variant2 FromJs_ManyMessagesEncryptFailed Id.codec Serialize.string
        |> Serialize.finishCustomType


encryptedDataCodec : Serialize.Codec e (EncryptedData a)
encryptedDataCodec =
    Serialize.map
        encryptedData
        (\(EncryptedData _ bytes) -> bytes)
        Serialize.bytes

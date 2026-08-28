port module Encryption exposing
    ( EncryptedData(..)
    , FromJs(..)
    , ToJs(..)
    , empty
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
import Bytes.Encode
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Id exposing (Id, UserId, Viewing_DmId)
import Json.Encode
import Serialize


{-| A message that has been encrypted. The type parameter records what it will be once
decrypted, which is only a note to the reader: nothing in Elm can see inside it.
-}
type EncryptedData a
    = EncryptedData Bytes


{-| Stands in for a field that has nothing in it yet. Embeds are the case that needs
this: working them out means reading the message, which only the two people in the
conversation can do, so the server has none to store.
-}
empty : EncryptedData a
empty =
    EncryptedData (Bytes.Encode.encode (Bytes.Encode.sequence []))


encode : EncryptedData a -> Json.Encode.Value
encode data =
    Json.Encode.string (toBase64 data)


toBase64 : EncryptedData a -> String
toBase64 (EncryptedData bytes) =
    Base64.fromBytes bytes |> Maybe.withDefault ""



-- PORTS


type ToJs data
    = ToJs_StoreSharedSecret { otherUserId : Id UserId, sharedSecret : Bytes }
    | ToJs_EncryptMessage { requestId : Int, otherUserId : Id UserId, data : data }


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


toJsCodec : Serialize.Codec e data -> Serialize.Codec e (ToJs data)
toJsCodec dataCodec =
    Serialize.customType
        (\toJs_StoreSharedSecretEncoder toJs_EncryptMessageEncoder value ->
            case value of
                ToJs_StoreSharedSecret argA ->
                    toJs_StoreSharedSecretEncoder argA

                ToJs_EncryptMessage argA ->
                    toJs_EncryptMessageEncoder argA
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
        |> Serialize.finishCustomType


type FromJs
    = FromJs_SharedSecretStored (Id UserId)
    | FromJs_SharedSecretFailed (Id UserId) String
    | FromJs_MessageEncrypted Int Bytes
    | FromJs_MessageEncryptFailed Int String


port encryption_to_js : Bytes -> Cmd msg


port encryption_from_js : (Bytes -> msg) -> Sub msg


fromJs : (Result String FromJs -> msg) -> Subscription FrontendOnly msg
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


fromJsCodec : Serialize.Codec e FromJs
fromJsCodec =
    Serialize.customType
        (\fromJs_SharedSecretStoredEncoder fromJs_SharedSecretFailedEncoder fromJs_MessageEncryptedEncoder fromJs_MessageEncryptFailedEncoder value ->
            case value of
                FromJs_SharedSecretStored argA ->
                    fromJs_SharedSecretStoredEncoder argA

                FromJs_SharedSecretFailed argA argB ->
                    fromJs_SharedSecretFailedEncoder argA argB

                FromJs_MessageEncrypted argA argB ->
                    fromJs_MessageEncryptedEncoder argA argB

                FromJs_MessageEncryptFailed argA argB ->
                    fromJs_MessageEncryptFailedEncoder argA argB
        )
        |> Serialize.variant1 FromJs_SharedSecretStored Id.codec
        |> Serialize.variant2 FromJs_SharedSecretFailed Id.codec Serialize.string
        |> Serialize.variant2 FromJs_MessageEncrypted Serialize.int Serialize.bytes
        |> Serialize.variant2 FromJs_MessageEncryptFailed Serialize.int Serialize.string
        |> Serialize.finishCustomType

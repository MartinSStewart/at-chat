port module Encryption exposing
    ( EncryptedData(..)
    , FromJs(..)
    , ToJs(..)
    , empty
    , encode
    , encryptMessage
    , fromBase64
    , fromJs
    , fromJsCodec
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
import Bytes.Encode
import Codec exposing (Codec)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Id exposing (Id, UserId, Viewing_DmId)
import Json.Decode
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


fromBase64 : String -> Maybe (EncryptedData a)
fromBase64 text =
    Maybe.map EncryptedData (Base64.toBytes text)



-- PORTS


type ToJs data
    = ToJs_StoreSharedSecret { otherUserId : Id UserId, sharedSecret : Bytes }
    | ToJs_EncryptMessage { requestId : Int, otherUserId : Id UserId, data : data }


encryptMessage : Int -> Viewing_DmId -> Serialize.Codec e a -> a -> Command FrontendOnly toMsg msg
encryptMessage requestId id dataCodec data =
    Serialize.encodeToBytes
        (toJsCodec dataCodec)
        (ToJs_EncryptMessage { requestId = requestId, otherUserId = id.otherUserId, data = data })
        |> Command.sendToJsBytes "encryption_to_js" encryption_to_js


toJsCodec : Serialize.Codec e data -> Serialize.Codec e (ToJs data)
toJsCodec dataCodec =
    Debug.todo ""


idCodec : Serialize.Codec e Int -> Serialize.Codec e (Id a)
idCodec =
    Serialize.map Id.fromInt Id.toInt


type FromJs
    = FromJs_SharedSecretStored (Id UserId)
    | FromJs_SharedSecretFailed (Id UserId) String
    | FromJs_MessageEncrypted Int String
    | FromJs_MessageEncryptFailed Int String


port encryption_to_js : Bytes -> Cmd msg


port encryption_from_js : (Json.Decode.Value -> msg) -> Sub msg


fromJs : (Result String FromJs -> msg) -> Subscription FrontendOnly msg
fromJs msg =
    Subscription.fromJs
        "encryption_from_js"
        encryption_from_js
        (\json ->
            Codec.decodeValue fromJsCodec json
                |> Result.mapError Json.Decode.errorToString
                |> msg
        )


fromJsCodec : Codec FromJs
fromJsCodec =
    Codec.custom
        (\eStored eStoreFailed eEncrypted eEncryptFailed value ->
            case value of
                FromJs_SharedSecretStored a ->
                    eStored a

                FromJs_SharedSecretFailed a b ->
                    eStoreFailed a b

                FromJs_MessageEncrypted a b ->
                    eEncrypted a b

                FromJs_MessageEncryptFailed a b ->
                    eEncryptFailed a b
        )
        |> Codec.variant1 "shared-secret-stored" FromJs_SharedSecretStored userIdCodec
        |> Codec.variant2 "shared-secret-failed" FromJs_SharedSecretFailed userIdCodec Codec.string
        |> Codec.variant2 "message-encrypted" FromJs_MessageEncrypted Codec.int Codec.string
        |> Codec.variant2 "message-encrypt-failed" FromJs_MessageEncryptFailed Codec.int Codec.string
        |> Codec.buildCustom

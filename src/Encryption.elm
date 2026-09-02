port module Encryption exposing
    ( BytesHash(..)
    , DecryptManyRequestId
    , DecryptRequestId
    , EncryptFileRequestId
    , EncryptManyRequestId
    , EncryptRequestId
    , EncryptedData(..)
    , FromJs(..)
    , ToJs(..)
    , decryptManyMessages
    , decryptMessage
    , encode
    , encryptFile
    , encryptManyMessages
    , encryptMessage
    , encryptedData
    , fromJs
    , fromJsCodec
    , hash
    , info
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

import Array
import Base64
import Bytes exposing (Bytes)
import Bytes.Decode
import Effect.Browser.Dom as Dom
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Time as Time
import Html
import Html.Attributes
import Id exposing (Id, UserId, Viewing_DmId)
import Json.Encode
import RichText
import SeqDict
import SeqSet
import Serialize
import Sticker exposing (AnimationMode(..))
import String.Nonempty exposing (NonemptyString(..))
import Ui
import Url exposing (Url)
import UserColor


{-| OpaqueVariants.
-}
type EncryptedData a
    = EncryptedData Bytes


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


type EncryptFileRequestId
    = EncryptFileRequestId Never


encode : EncryptedData a -> Json.Encode.Value
encode data =
    Json.Encode.string (toBase64 data)


toBase64 : EncryptedData a -> String
toBase64 (EncryptedData bytes) =
    Base64.fromBytes bytes |> Maybe.withDefault ""


{-| A very low effort hash of the encrypted data since the data is already randomly distributed.
-}
hash : EncryptedData a -> BytesHash
hash (EncryptedData bytes) =
    Bytes.Decode.decode
        (Bytes.Decode.map2
            (\high low -> BytesHash (high * 4294967296 + low))
            (Bytes.Decode.unsignedInt16 Bytes.BE)
            (Bytes.Decode.unsignedInt32 Bytes.BE)
        )
        bytes
        |> Maybe.withDefault (BytesHash 0)


encryptedData : Bytes -> EncryptedData a
encryptedData =
    EncryptedData


info : msg -> Ui.Element msg
info noOp =
    NonemptyString
        '#'
        """ End-to-end encryption (E2EE) in at-chat


## Quick summary of E2EE
With E2EE enabled your messages are encrypted when stored on the server. This means, even if a hacker gets access to the at-chat server data, they won't be able to read your conversation.


## Limitations
* One of the web's best features is that it's very easy to distribute new versions of a website/webapp. Unfortunately for E2EE this is a disadvantage. Anyone with the power to change what JS code the server sends to a client (either a hacker or malicious admin) can modify the webapp to covertly spy on you since messages are not encrypted once loaded on your webapp.
* Because Browsers can't be relied upon to store data indefinitely, some compromises have been made to user experience. [Forward secrecy](https://en.wikipedia.org/wiki/Forward_secrecy) is not supported and you have to manually store your private key outside of at-chat.
* Browser extensions can also potentially spy on your conversation
* Video streaming is not available and file uploading might take longer

For these reasons, consider at-chat's E2EE "best effort". It will protect you from a lazy malicious admin (who can't be bothered of going through the trouble of deploying spyware to the client) and from a hacker who gets read-only access to the server.

If privacy is important to you, Signal is probably a better choice.


## What exactly gets encrypted
at-chat encrypts message contents and attached files.

The following is not encrypted:
* Message creation time
* Approximate size of message contents
* Who wrote the message
* If the message is a reply to a previous message
* Drawings
* Message edit time
* Emoji reactions
* Games
* Voice chats (E2EE voice chats might be added in the future)
"""
        |> RichText.fromNonemptyString Time.utc SeqDict.empty
        |> RichText.view
            (Dom.id "e2ee-info")
            1000
            (\_ -> noOp)
            (\_ -> noOp)
            (\_ -> noOp)
            { domainWhitelist = SeqSet.empty
            , revealedSpoilers = SeqSet.empty
            , users = SeqDict.empty
            , attachedFiles = SeqDict.empty
            , stickers = SeqDict.empty
            , customEmojis = SeqDict.empty
            , animationMode = LoopAFewTimesOnLoad
            , timezone = Time.utc
            , time = Time.millisToPosix 0
            , drawings = SeqDict.empty
            , embedDrawings = SeqDict.empty
            , drawingUserColor = \_ -> UserColor.default
            , isSelectingAnchor = False
            , devicePixelRatio = 1
            , isHovered = False
            }
            Array.empty
        |> Html.div [ Html.Attributes.style "white-space" "pre-wrap" ]
        |> Ui.html
        |> Ui.el [ Ui.centerX, Ui.widthMax 1000, Ui.paddingXY 16 32 ]



-- PORTS


type ToJs data
    = ToJs_StoreSharedSecret { otherUserId : Id UserId, sharedSecret : Bytes }
    | ToJs_EncryptNewMessage { requestId : Id EncryptRequestId, otherUserId : Id UserId, data : data }
    | ToJs_DecryptNewMessage { requestId : Id DecryptRequestId, otherUserId : Id UserId, data : Bytes }
    | ToJs_DecryptManyMessages { requestId : Id DecryptManyRequestId, otherUserId : Id UserId, data : List Bytes }
    | ToJs_EncryptManyMessages { requestId : Id EncryptManyRequestId, otherUserId : Id UserId, data : List Bytes }
    | ToJs_EncryptFile { requestId : Id EncryptFileRequestId, data : Bytes }


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
decryptMessage requestId id (EncryptedData data) =
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
            , data = List.map (\(EncryptedData bytes) -> bytes) messages
            }
        )
        |> Command.sendToJsBytes "encryption_to_js" encryption_to_js


{-| A file gets a key of its own rather than the conversation's. The key travels inside
the message the file is attached to, which is itself encrypted, so the server holds the
ciphertext and nothing that opens it.
-}
encryptFile : Id EncryptFileRequestId -> Bytes -> Command FrontendOnly toMsg msg
encryptFile requestId data =
    Serialize.encodeToBytes
        (toJsCodec Serialize.unit)
        (ToJs_EncryptFile { requestId = requestId, data = data })
        |> Command.sendToJsBytes "encryption_to_js" encryption_to_js


toJsCodec : Serialize.Codec e data -> Serialize.Codec e (ToJs data)
toJsCodec dataCodec =
    Serialize.customType
        (\a b c d e f value ->
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

                ToJs_EncryptFile argA ->
                    f argA
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
        |> Serialize.variant1
            ToJs_EncryptFile
            (Serialize.record
                (\requestId data -> { requestId = requestId, data = data })
                |> Serialize.field .requestId Id.codec
                |> Serialize.field .data Serialize.bytes
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
    | FromJs_FileEncrypted (Id EncryptFileRequestId) { key : Bytes, data : Bytes }
    | FromJs_FileEncryptFailed (Id EncryptFileRequestId) String


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
        (\a b c d e f g h i j k value ->
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

                FromJs_FileEncrypted argA argB ->
                    j argA argB

                FromJs_FileEncryptFailed argA argB ->
                    k argA argB
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
        |> Serialize.variant2
            FromJs_FileEncrypted
            Id.codec
            (Serialize.record (\key data -> { key = key, data = data })
                |> Serialize.field .key Serialize.bytes
                |> Serialize.field .data Serialize.bytes
                |> Serialize.finishRecord
            )
        |> Serialize.variant2 FromJs_FileEncryptFailed Id.codec Serialize.string
        |> Serialize.finishCustomType


encryptedDataCodec : Serialize.Codec e (EncryptedData a)
encryptedDataCodec =
    Serialize.map
        encryptedData
        (\(EncryptedData bytes) -> bytes)
        Serialize.bytes

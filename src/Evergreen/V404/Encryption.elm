module Evergreen.V404.Encryption exposing (..)

import Bytes
import Evergreen.V404.FileStatus
import Evergreen.V404.Id


type EncryptRequestId
    = EncryptRequestId Never


type EncryptedData a
    = EncryptedData Bytes.Bytes


type DecryptRequestId
    = DecryptRequestId Never


type DecryptManyRequestId
    = DecryptManyRequestId Never


type EncryptManyRequestId
    = EncryptManyRequestId Never


type EncryptFileRequestId
    = EncryptFileRequestId Never


type FromJs a
    = FromJs_SharedSecretStored (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
    | FromJs_SharedSecretFailed (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) String
    | FromJs_NewMessageEncrypted (Evergreen.V404.Id.Id EncryptRequestId) (EncryptedData a)
    | FromJs_NewMessageEncryptFailed (Evergreen.V404.Id.Id EncryptRequestId) String
    | FromJs_NewMessageDecrypted (Evergreen.V404.Id.Id DecryptRequestId) a
    | FromJs_NewMessageDecryptFailed (Evergreen.V404.Id.Id DecryptRequestId)
    | FromJs_ManyMessagesDecrypted (Evergreen.V404.Id.Id DecryptManyRequestId) (List (Result () a))
    | FromJs_ManyMessagesEncrypted (Evergreen.V404.Id.Id EncryptManyRequestId) (List (EncryptedData a))
    | FromJs_ManyMessagesEncryptFailed (Evergreen.V404.Id.Id EncryptManyRequestId) String
    | FromJs_FileEncrypted
        (Evergreen.V404.Id.Id EncryptFileRequestId)
        { key : Bytes.Bytes
        , data : Bytes.Bytes
        , thumbnail : Maybe Bytes.Bytes
        , measured : Maybe Evergreen.V404.FileStatus.MeasuredFile
        }
    | FromJs_FileEncryptFailed (Evergreen.V404.Id.Id EncryptFileRequestId) String


type BytesHash
    = BytesHash Int

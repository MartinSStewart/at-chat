module Evergreen.V373.Encryption exposing (..)

import Bytes
import Evergreen.V373.FileStatus
import Evergreen.V373.Id


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
    = FromJs_SharedSecretStored (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | FromJs_SharedSecretFailed (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) String
    | FromJs_NewMessageEncrypted (Evergreen.V373.Id.Id EncryptRequestId) (EncryptedData a)
    | FromJs_NewMessageEncryptFailed (Evergreen.V373.Id.Id EncryptRequestId) String
    | FromJs_NewMessageDecrypted (Evergreen.V373.Id.Id DecryptRequestId) a
    | FromJs_NewMessageDecryptFailed (Evergreen.V373.Id.Id DecryptRequestId)
    | FromJs_ManyMessagesDecrypted (Evergreen.V373.Id.Id DecryptManyRequestId) (List (Result () a))
    | FromJs_ManyMessagesEncrypted (Evergreen.V373.Id.Id EncryptManyRequestId) (List (EncryptedData a))
    | FromJs_ManyMessagesEncryptFailed (Evergreen.V373.Id.Id EncryptManyRequestId) String
    | FromJs_FileEncrypted
        (Evergreen.V373.Id.Id EncryptFileRequestId)
        { key : Bytes.Bytes
        , data : Bytes.Bytes
        , thumbnail : Maybe Bytes.Bytes
        , measured : Maybe Evergreen.V373.FileStatus.MeasuredFile
        }
    | FromJs_FileEncryptFailed (Evergreen.V373.Id.Id EncryptFileRequestId) String


type BytesHash
    = BytesHash Int

module Evergreen.V384.Encryption exposing (..)

import Bytes
import Evergreen.V384.FileStatus
import Evergreen.V384.Id


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
    = FromJs_SharedSecretStored (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | FromJs_SharedSecretFailed (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) String
    | FromJs_NewMessageEncrypted (Evergreen.V384.Id.Id EncryptRequestId) (EncryptedData a)
    | FromJs_NewMessageEncryptFailed (Evergreen.V384.Id.Id EncryptRequestId) String
    | FromJs_NewMessageDecrypted (Evergreen.V384.Id.Id DecryptRequestId) a
    | FromJs_NewMessageDecryptFailed (Evergreen.V384.Id.Id DecryptRequestId)
    | FromJs_ManyMessagesDecrypted (Evergreen.V384.Id.Id DecryptManyRequestId) (List (Result () a))
    | FromJs_ManyMessagesEncrypted (Evergreen.V384.Id.Id EncryptManyRequestId) (List (EncryptedData a))
    | FromJs_ManyMessagesEncryptFailed (Evergreen.V384.Id.Id EncryptManyRequestId) String
    | FromJs_FileEncrypted
        (Evergreen.V384.Id.Id EncryptFileRequestId)
        { key : Bytes.Bytes
        , data : Bytes.Bytes
        , thumbnail : Maybe Bytes.Bytes
        , measured : Maybe Evergreen.V384.FileStatus.MeasuredFile
        }
    | FromJs_FileEncryptFailed (Evergreen.V384.Id.Id EncryptFileRequestId) String


type BytesHash
    = BytesHash Int

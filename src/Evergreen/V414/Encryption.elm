module Evergreen.V414.Encryption exposing (..)

import Bytes
import Evergreen.V414.FileStatus
import Evergreen.V414.Id


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
    = FromJs_SharedSecretStored (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
    | FromJs_SharedSecretFailed (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) String
    | FromJs_NewMessageEncrypted (Evergreen.V414.Id.Id EncryptRequestId) (EncryptedData a)
    | FromJs_NewMessageEncryptFailed (Evergreen.V414.Id.Id EncryptRequestId) String
    | FromJs_NewMessageDecrypted (Evergreen.V414.Id.Id DecryptRequestId) a
    | FromJs_NewMessageDecryptFailed (Evergreen.V414.Id.Id DecryptRequestId)
    | FromJs_ManyMessagesDecrypted (Evergreen.V414.Id.Id DecryptManyRequestId) (List (Result () a))
    | FromJs_ManyMessagesEncrypted (Evergreen.V414.Id.Id EncryptManyRequestId) (List (EncryptedData a))
    | FromJs_ManyMessagesEncryptFailed (Evergreen.V414.Id.Id EncryptManyRequestId) String
    | FromJs_FileEncrypted
        (Evergreen.V414.Id.Id EncryptFileRequestId)
        { key : Bytes.Bytes
        , data : Bytes.Bytes
        , thumbnail : Maybe Bytes.Bytes
        , measured : Maybe Evergreen.V414.FileStatus.MeasuredFile
        }
    | FromJs_FileEncryptFailed (Evergreen.V414.Id.Id EncryptFileRequestId) String


type BytesHash
    = BytesHash Int

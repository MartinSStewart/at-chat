module Evergreen.V387.Encryption exposing (..)

import Bytes
import Evergreen.V387.FileStatus
import Evergreen.V387.Id


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
    = FromJs_SharedSecretStored (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | FromJs_SharedSecretFailed (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) String
    | FromJs_NewMessageEncrypted (Evergreen.V387.Id.Id EncryptRequestId) (EncryptedData a)
    | FromJs_NewMessageEncryptFailed (Evergreen.V387.Id.Id EncryptRequestId) String
    | FromJs_NewMessageDecrypted (Evergreen.V387.Id.Id DecryptRequestId) a
    | FromJs_NewMessageDecryptFailed (Evergreen.V387.Id.Id DecryptRequestId)
    | FromJs_ManyMessagesDecrypted (Evergreen.V387.Id.Id DecryptManyRequestId) (List (Result () a))
    | FromJs_ManyMessagesEncrypted (Evergreen.V387.Id.Id EncryptManyRequestId) (List (EncryptedData a))
    | FromJs_ManyMessagesEncryptFailed (Evergreen.V387.Id.Id EncryptManyRequestId) String
    | FromJs_FileEncrypted
        (Evergreen.V387.Id.Id EncryptFileRequestId)
        { key : Bytes.Bytes
        , data : Bytes.Bytes
        , thumbnail : Maybe Bytes.Bytes
        , measured : Maybe Evergreen.V387.FileStatus.MeasuredFile
        }
    | FromJs_FileEncryptFailed (Evergreen.V387.Id.Id EncryptFileRequestId) String


type BytesHash
    = BytesHash Int

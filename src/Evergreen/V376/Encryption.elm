module Evergreen.V376.Encryption exposing (..)

import Bytes
import Evergreen.V376.FileStatus
import Evergreen.V376.Id


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
    = FromJs_SharedSecretStored (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | FromJs_SharedSecretFailed (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) String
    | FromJs_NewMessageEncrypted (Evergreen.V376.Id.Id EncryptRequestId) (EncryptedData a)
    | FromJs_NewMessageEncryptFailed (Evergreen.V376.Id.Id EncryptRequestId) String
    | FromJs_NewMessageDecrypted (Evergreen.V376.Id.Id DecryptRequestId) a
    | FromJs_NewMessageDecryptFailed (Evergreen.V376.Id.Id DecryptRequestId)
    | FromJs_ManyMessagesDecrypted (Evergreen.V376.Id.Id DecryptManyRequestId) (List (Result () a))
    | FromJs_ManyMessagesEncrypted (Evergreen.V376.Id.Id EncryptManyRequestId) (List (EncryptedData a))
    | FromJs_ManyMessagesEncryptFailed (Evergreen.V376.Id.Id EncryptManyRequestId) String
    | FromJs_FileEncrypted
        (Evergreen.V376.Id.Id EncryptFileRequestId)
        { key : Bytes.Bytes
        , data : Bytes.Bytes
        , thumbnail : Maybe Bytes.Bytes
        , measured : Maybe Evergreen.V376.FileStatus.MeasuredFile
        }
    | FromJs_FileEncryptFailed (Evergreen.V376.Id.Id EncryptFileRequestId) String


type BytesHash
    = BytesHash Int

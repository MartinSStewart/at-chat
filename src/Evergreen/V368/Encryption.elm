module Evergreen.V368.Encryption exposing (..)

import Bytes
import Evergreen.V368.FileStatus
import Evergreen.V368.Id


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
    = FromJs_SharedSecretStored (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | FromJs_SharedSecretFailed (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) String
    | FromJs_NewMessageEncrypted (Evergreen.V368.Id.Id EncryptRequestId) (EncryptedData a)
    | FromJs_NewMessageEncryptFailed (Evergreen.V368.Id.Id EncryptRequestId) String
    | FromJs_NewMessageDecrypted (Evergreen.V368.Id.Id DecryptRequestId) a
    | FromJs_NewMessageDecryptFailed (Evergreen.V368.Id.Id DecryptRequestId)
    | FromJs_ManyMessagesDecrypted (Evergreen.V368.Id.Id DecryptManyRequestId) (List (Result () a))
    | FromJs_ManyMessagesEncrypted (Evergreen.V368.Id.Id EncryptManyRequestId) (List (EncryptedData a))
    | FromJs_ManyMessagesEncryptFailed (Evergreen.V368.Id.Id EncryptManyRequestId) String
    | FromJs_FileEncrypted
        (Evergreen.V368.Id.Id EncryptFileRequestId)
        { key : Bytes.Bytes
        , data : Bytes.Bytes
        , thumbnail : Maybe Bytes.Bytes
        , measured : Maybe Evergreen.V368.FileStatus.MeasuredFile
        }
    | FromJs_FileEncryptFailed (Evergreen.V368.Id.Id EncryptFileRequestId) String


type BytesHash
    = BytesHash Int

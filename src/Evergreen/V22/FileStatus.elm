module Evergreen.V22.FileStatus exposing (..)

import Effect.Http
import Evergreen.V22.FileName


type FileId
    = FileStatusId Never


type ContentType
    = ContentType String


type FileHash
    = FileHash String


type alias FileData =
    { fileName : Evergreen.V22.FileName.FileName
    , fileSize : Int
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading Evergreen.V22.FileName.FileName Int ContentType
    | FileUploaded FileData
    | FileError Effect.Http.Error

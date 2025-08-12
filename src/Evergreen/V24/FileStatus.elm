module Evergreen.V24.FileStatus exposing (..)

import Effect.Http
import Evergreen.V24.FileName


type FileHash
    = FileHash String


type FileId
    = FileStatusId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V24.FileName.FileName
    , fileSize : Int
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading Evergreen.V24.FileName.FileName Int ContentType
    | FileUploaded FileData
    | FileError Effect.Http.Error

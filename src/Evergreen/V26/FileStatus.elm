module Evergreen.V26.FileStatus exposing (..)

import Effect.Http
import Evergreen.V26.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V26.FileName.FileName
    , fileSize : Int
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading Evergreen.V26.FileName.FileName Int ContentType
    | FileUploaded FileData
    | FileError Effect.Http.Error

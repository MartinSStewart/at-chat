module Evergreen.V27.FileStatus exposing (..)

import Effect.Http
import Evergreen.V27.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V27.FileName.FileName
    , fileSize : Int
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading Evergreen.V27.FileName.FileName Int ContentType
    | FileUploaded FileData
    | FileError Effect.Http.Error

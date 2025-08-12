module Evergreen.V23.FileStatus exposing (..)

import Effect.Http
import Evergreen.V23.FileName


type FileId
    = FileStatusId Never


type ContentType
    = ContentType Int


type FileHash
    = FileHash String


type alias FileData =
    { fileName : Evergreen.V23.FileName.FileName
    , fileSize : Int
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading Evergreen.V23.FileName.FileName Int ContentType
    | FileUploaded FileData
    | FileError Effect.Http.Error

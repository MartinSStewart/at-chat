module Evergreen.V30.FileStatus exposing (..)

import Effect.Http
import Evergreen.V30.Coord
import Evergreen.V30.CssPixels
import Evergreen.V30.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V30.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V30.Coord.Coord Evergreen.V30.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading Evergreen.V30.FileName.FileName Int ContentType
    | FileUploaded FileData
    | FileError Effect.Http.Error

module Evergreen.V29.FileStatus exposing (..)

import Effect.Http
import Evergreen.V29.Coord
import Evergreen.V29.CssPixels
import Evergreen.V29.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V29.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading Evergreen.V29.FileName.FileName Int ContentType
    | FileUploaded FileData
    | FileError Effect.Http.Error

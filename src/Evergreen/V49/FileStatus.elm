module Evergreen.V49.FileStatus exposing (..)

import Effect.Http
import Evergreen.V49.Coord
import Evergreen.V49.CssPixels
import Evergreen.V49.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V49.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V49.Coord.Coord Evergreen.V49.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V49.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V49.FileName.FileName Int ContentType Effect.Http.Error

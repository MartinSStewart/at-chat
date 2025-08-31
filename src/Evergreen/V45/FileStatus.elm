module Evergreen.V45.FileStatus exposing (..)

import Effect.Http
import Evergreen.V45.Coord
import Evergreen.V45.CssPixels
import Evergreen.V45.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V45.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V45.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V45.FileName.FileName Int ContentType Effect.Http.Error

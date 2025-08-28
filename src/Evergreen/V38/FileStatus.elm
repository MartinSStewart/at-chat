module Evergreen.V38.FileStatus exposing (..)

import Effect.Http
import Evergreen.V38.Coord
import Evergreen.V38.CssPixels
import Evergreen.V38.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V38.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V38.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V38.FileName.FileName Int ContentType Effect.Http.Error

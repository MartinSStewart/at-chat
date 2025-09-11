module Evergreen.V54.FileStatus exposing (..)

import Effect.Http
import Evergreen.V54.Coord
import Evergreen.V54.CssPixels
import Evergreen.V54.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V54.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V54.Coord.Coord Evergreen.V54.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V54.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V54.FileName.FileName Int ContentType Effect.Http.Error

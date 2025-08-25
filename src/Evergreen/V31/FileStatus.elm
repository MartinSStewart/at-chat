module Evergreen.V31.FileStatus exposing (..)

import Effect.Http
import Evergreen.V31.Coord
import Evergreen.V31.CssPixels
import Evergreen.V31.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V31.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V31.Coord.Coord Evergreen.V31.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V31.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V31.FileName.FileName Int ContentType Effect.Http.Error

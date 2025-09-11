module Evergreen.V53.FileStatus exposing (..)

import Effect.Http
import Evergreen.V53.Coord
import Evergreen.V53.CssPixels
import Evergreen.V53.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V53.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V53.Coord.Coord Evergreen.V53.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V53.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V53.FileName.FileName Int ContentType Effect.Http.Error

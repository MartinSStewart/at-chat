module Evergreen.V33.FileStatus exposing (..)

import Effect.Http
import Evergreen.V33.Coord
import Evergreen.V33.CssPixels
import Evergreen.V33.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V33.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V33.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V33.FileName.FileName Int ContentType Effect.Http.Error

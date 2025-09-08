module Evergreen.V52.FileStatus exposing (..)

import Effect.Http
import Evergreen.V52.Coord
import Evergreen.V52.CssPixels
import Evergreen.V52.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V52.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V52.Coord.Coord Evergreen.V52.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V52.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V52.FileName.FileName Int ContentType Effect.Http.Error

module Evergreen.V41.FileStatus exposing (..)

import Effect.Http
import Evergreen.V41.Coord
import Evergreen.V41.CssPixels
import Evergreen.V41.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V41.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V41.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V41.FileName.FileName Int ContentType Effect.Http.Error

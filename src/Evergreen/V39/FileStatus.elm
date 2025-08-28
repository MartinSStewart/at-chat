module Evergreen.V39.FileStatus exposing (..)

import Effect.Http
import Evergreen.V39.Coord
import Evergreen.V39.CssPixels
import Evergreen.V39.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V39.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V39.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V39.FileName.FileName Int ContentType Effect.Http.Error

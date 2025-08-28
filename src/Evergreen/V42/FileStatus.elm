module Evergreen.V42.FileStatus exposing (..)

import Effect.Http
import Evergreen.V42.Coord
import Evergreen.V42.CssPixels
import Evergreen.V42.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V42.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V42.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V42.FileName.FileName Int ContentType Effect.Http.Error

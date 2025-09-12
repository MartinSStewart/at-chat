module Evergreen.V56.FileStatus exposing (..)

import Effect.Http
import Evergreen.V56.Coord
import Evergreen.V56.CssPixels
import Evergreen.V56.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V56.FileName.FileName
    , fileSize : Int
    , imageSize : Maybe (Evergreen.V56.Coord.Coord Evergreen.V56.CssPixels.CssPixels)
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V56.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V56.FileName.FileName Int ContentType Effect.Http.Error


type alias UploadResponse =
    { fileHash : FileHash
    , imageSize : Maybe (Evergreen.V56.Coord.Coord Evergreen.V56.CssPixels.CssPixels)
    }

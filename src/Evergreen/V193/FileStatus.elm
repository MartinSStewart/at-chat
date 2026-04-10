module Evergreen.V193.FileStatus exposing (..)

import Effect.Http
import Evergreen.V193.Coord
import Evergreen.V193.CssPixels
import Evergreen.V193.FileName


type FileHash
    = FileHash String


type FileId
    = FileId Never


type Orientation
    = NoChange
    | Rotation90
    | Rotation180
    | Rotation270
    | Mirrored
    | MirroredRotation90
    | MirroredRotation180
    | MirroredRotation270


type alias Location =
    { lat : Float
    , lon : Float
    }


type alias ExposureTime =
    { numerator : Int
    , denominator : Int
    }


type alias ImageMetadata =
    { imageSize : Evergreen.V193.Coord.Coord Evergreen.V193.CssPixels.CssPixels
    , orientation : Maybe Orientation
    , gpsLocation : Maybe Location
    , cameraOwner : Maybe String
    , exposureTime : Maybe ExposureTime
    , fNumber : Maybe Float
    , focalLength : Maybe Float
    , isoSpeedRating : Maybe Int
    , make : Maybe String
    , model : Maybe String
    , software : Maybe String
    , userComment : Maybe String
    }


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V193.FileName.FileName
    , fileSize : Int
    , imageMetadata : Maybe ImageMetadata
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V193.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V193.FileName.FileName Int ContentType Effect.Http.Error


type alias FileDataWithImage =
    { fileName : Evergreen.V193.FileName.FileName
    , fileSize : Int
    , imageMetadata : ImageMetadata
    , contentType : ContentType
    , fileHash : FileHash
    }


type alias UploadResponse =
    { fileHash : FileHash
    , imageSize : Maybe ImageMetadata
    }

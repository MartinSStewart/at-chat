module Evergreen.V77.FileStatus exposing (..)

import Effect.Http
import Evergreen.V77.Coord
import Evergreen.V77.CssPixels
import Evergreen.V77.FileName


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
    { imageSize : Evergreen.V77.Coord.Coord Evergreen.V77.CssPixels.CssPixels
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
    { fileName : Evergreen.V77.FileName.FileName
    , fileSize : Int
    , imageMetadata : Maybe ImageMetadata
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V77.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V77.FileName.FileName Int ContentType Effect.Http.Error


type alias FileDataWithImage =
    { fileName : Evergreen.V77.FileName.FileName
    , fileSize : Int
    , imageMetadata : ImageMetadata
    , contentType : ContentType
    , fileHash : FileHash
    }


type alias UploadResponse =
    { fileHash : FileHash
    , imageSize : Maybe ImageMetadata
    }

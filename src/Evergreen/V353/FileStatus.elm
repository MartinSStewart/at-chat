module Evergreen.V353.FileStatus exposing (..)

import Duration
import Effect.Http
import Effect.Time
import Evergreen.V353.Coord
import Evergreen.V353.CssPixels
import Evergreen.V353.FileName
import Quantity


type FileHash
    = FileHash String


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
    { imageSize : Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels
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


type VideoFrames
    = VideoFrames Never


type alias VideoMetadata =
    { videoSize : Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels
    , frames : Maybe (Quantity.Quantity Int VideoFrames)
    , createdAt : Maybe Effect.Time.Posix
    , orientation : Orientation
    , frameRate : Maybe (Quantity.Quantity Float (Quantity.Rate VideoFrames Duration.Seconds))
    , codec : Maybe String
    , title : Maybe String
    , gpsLocation : Maybe Location
    }


type alias UploadResponse =
    { fileHash : FileHash
    , imageMetadata : Maybe ImageMetadata
    , videoMetadata : Maybe VideoMetadata
    }


type FileId
    = FileId Never


type FileMetadata
    = FileMetadata_Image ImageMetadata
    | FileMetadata_Video VideoMetadata


type ContentType
    = ContentType Int


type alias FileData =
    { fileName : Evergreen.V353.FileName.FileName
    , fileSize : Int
    , metadata : Maybe FileMetadata
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading
        Evergreen.V353.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
    | FileUploaded FileData
    | FileError Evergreen.V353.FileName.FileName Int ContentType Effect.Http.Error


type alias FileDataWithImage =
    { fileName : Evergreen.V353.FileName.FileName
    , fileSize : Int
    , metadata : FileMetadata
    , contentType : ContentType
    , fileHash : FileHash
    }

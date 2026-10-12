module Evergreen.V405.FileStatus exposing (..)

import Bytes
import Duration
import Effect.Http
import Effect.Time
import Evergreen.V405.Coord
import Evergreen.V405.CssPixels
import Evergreen.V405.FileName
import Evergreen.V405.SafeFloat


type FileId
    = FileId Never


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
    { lat : Evergreen.V405.SafeFloat.SafeFloat
    , lon : Evergreen.V405.SafeFloat.SafeFloat
    }


type alias ExposureTime =
    { numerator : Int
    , denominator : Int
    }


type alias ImageMetadata =
    { imageSize : Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels
    , orientation : Maybe Orientation
    , gpsLocation : Maybe Location
    , cameraOwner : Maybe String
    , exposureTime : Maybe ExposureTime
    , fNumber : Maybe Evergreen.V405.SafeFloat.SafeFloat
    , focalLength : Maybe Evergreen.V405.SafeFloat.SafeFloat
    , isoSpeedRating : Maybe Int
    , make : Maybe String
    , model : Maybe String
    , software : Maybe String
    , userComment : Maybe String
    }


type alias VideoMetadata =
    { videoSize : Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels
    , createdAt : Maybe Effect.Time.Posix
    , orientation : Orientation
    , codec : Maybe String
    , title : Maybe String
    , gpsLocation : Maybe Location
    , duration : Maybe Duration.Duration
    }


type alias UploadResponse =
    { fileHash : FileHash
    , imageMetadata : Maybe ImageMetadata
    , videoMetadata : Maybe VideoMetadata
    }


type FileMetadata
    = FileMetadata_Image ImageMetadata
    | FileMetadata_Video VideoMetadata


type ContentType
    = ContentType Int


type AesPrivateKey
    = AesPrivateKey Bytes.Bytes


type EncryptedThumbnail
    = NoEncryptedThumbnail
    | HasEncryptedThumbnail


type IsEncrypted
    = IsNotEncrypted
    | IsEncrypted AesPrivateKey EncryptedThumbnail


type alias FileData =
    { fileName : Evergreen.V405.FileName.FileName
    , fileSize : Int
    , metadata : Maybe FileMetadata
    , contentType : ContentType
    , fileHash : FileHash
    , isEncrypted : IsEncrypted
    }


type MeasuredFile
    = MeasuredImage (Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels)
    | MeasuredVideo (Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels) (Maybe Duration.Duration)


type FileStatus
    = FileUploading
        Evergreen.V405.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
        IsEncrypted
    | FileUploaded FileData
    | FileError Evergreen.V405.FileName.FileName Int ContentType Effect.Http.Error IsEncrypted


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels)
    }


type alias FileDataWithImage =
    { fileName : Evergreen.V405.FileName.FileName
    , fileSize : Int
    , metadata : FileMetadata
    , contentType : ContentType
    , fileHash : FileHash
    , isEncrypted : IsEncrypted
    }

module Evergreen.V422.FileStatus exposing (..)

import Bytes
import Duration
import Effect.Http
import Effect.Time
import Evergreen.V422.Coord
import Evergreen.V422.CssPixels
import Evergreen.V422.FileName
import Evergreen.V422.SafeFloat


type ContentType
    = ContentType Int


type PeerToPeerId
    = PeerToPeerId String


type alias PeerToPeerFile =
    { fileName : Evergreen.V422.FileName.FileName
    , fileSize : Int
    , contentType : ContentType
    , peerToPeerId : PeerToPeerId
    }


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
    { lat : Evergreen.V422.SafeFloat.SafeFloat
    , lon : Evergreen.V422.SafeFloat.SafeFloat
    }


type alias ExposureTime =
    { numerator : Int
    , denominator : Int
    }


type alias ImageMetadata =
    { imageSize : Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels
    , orientation : Maybe Orientation
    , gpsLocation : Maybe Location
    , cameraOwner : Maybe String
    , exposureTime : Maybe ExposureTime
    , fNumber : Maybe Evergreen.V422.SafeFloat.SafeFloat
    , focalLength : Maybe Evergreen.V422.SafeFloat.SafeFloat
    , isoSpeedRating : Maybe Int
    , make : Maybe String
    , model : Maybe String
    , software : Maybe String
    , userComment : Maybe String
    }


type alias VideoMetadata =
    { videoSize : Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels
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


type AesPrivateKey
    = AesPrivateKey Bytes.Bytes


type EncryptedThumbnail
    = NoEncryptedThumbnail
    | HasEncryptedThumbnail


type IsEncrypted
    = IsNotEncrypted
    | IsEncrypted AesPrivateKey EncryptedThumbnail


type alias FileData =
    { fileName : Evergreen.V422.FileName.FileName
    , fileSize : Int
    , metadata : Maybe FileMetadata
    , contentType : ContentType
    , fileHash : FileHash
    , isEncrypted : IsEncrypted
    }


type Attachment
    = Stored FileData
    | PeerToPeer PeerToPeerFile


type MeasuredFile
    = MeasuredImage (Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels)
    | MeasuredVideo (Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels) (Maybe Duration.Duration)


type FileStatus
    = FileUploading
        Evergreen.V422.FileName.FileName
        { sent : Int
        , size : Int
        }
        ContentType
        IsEncrypted
    | FileUploaded FileData
    | FilePeerToPeer PeerToPeerFile
    | FileError Evergreen.V422.FileName.FileName Int ContentType Effect.Http.Error IsEncrypted


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels)
    }


type alias FileDataWithImage =
    { fileName : Evergreen.V422.FileName.FileName
    , fileSize : Int
    , metadata : FileMetadata
    , contentType : ContentType
    , fileHash : FileHash
    , isEncrypted : IsEncrypted
    }

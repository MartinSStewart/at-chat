module FileStatus exposing
    ( AesPrivateKey
    , ContentType(..)
    , ContentTypeType(..)
    , ExposureTime
    , FileData
    , FileDataWithImage
    , FileHash(..)
    , FileId
    , FileMetadata(..)
    , FileStatus(..)
    , ImageMetadata
    , IsEncrypted(..)
    , Location
    , Orientation(..)
    , UploadResponse
    , UploadUrlRequest
    , VideoFrames
    , VideoMetadata
    , addFileHash
    , aesPrivateKey
    , contentType
    , contentTypeType
    , contentTypes
    , discordStickerUrl
    , domain
    , fileDataSerializeCodec
    , fileHash
    , fileUrl
    , gifContent
    , hasUploadingFile
    , imageHasMetadata
    , imageInfoView
    , imageMaxHeight
    , jsonContent
    , onlyUploadedFiles
    , pngContent
    , progressToString
    , secretKeyHeader
    , sizeToString
    , thumbnailUrl
    , unknownContentType
    , uploadAvatar
    , uploadBackup
    , uploadBytes
    , uploadEncryptedFile
    , uploadFile
    , uploadGameFile
    , uploadResponseCodec
    , uploadResponseMetadata
    , uploadString
    , uploadTrackerId
    , uploadUrl
    , uploadUrlCodec
    , videoHasMetadata
    , webpContent
    , websocketDomain
    )

import Bytes exposing (Bytes)
import Codec exposing (Codec)
import CodecExtra
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord
import Duration exposing (Duration, Seconds)
import Effect.Browser.Dom as Dom
import Effect.Command exposing (BackendOnly, Command)
import Effect.File exposing (File)
import Effect.Http as Http
import Effect.Task exposing (Task)
import Effect.Time as Time
import Env
import FileName exposing (FileName)
import Html
import Html.Attributes
import Icons
import Id exposing (AnyGuildOrDmId(..), DiscordGuildOrDmId(..), GuildOrDmId(..), Id, ThreadRoute(..))
import Json.Decode
import MyUi
import OneToOne exposing (OneToOne)
import Quantity exposing (Quantity, Rate)
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import Serialize
import StringExtra
import Ui exposing (Element)


type alias FileData =
    { fileName : FileName
    , fileSize : Int
    , metadata : Maybe FileMetadata
    , contentType : ContentType
    , fileHash : FileHash
    , isEncrypted : IsEncrypted
    }


type FileMetadata
    = FileMetadata_Image ImageMetadata
    | FileMetadata_Video VideoMetadata


type alias FileDataWithImage =
    { fileName : FileName
    , fileSize : Int
    , metadata : FileMetadata
    , contentType : ContentType
    , fileHash : FileHash
    }


type FileStatus
    = FileUploading FileName { sent : Int, size : Int } ContentType IsEncrypted
    | FileUploaded FileData
    | FileError FileName Int ContentType Http.Error IsEncrypted


type IsEncrypted
    = IsNotEncrypted
    | IsEncrypted AesPrivateKey


type AesPrivateKey
    = AesPrivateKey Bytes


aesPrivateKey : Bytes -> AesPrivateKey
aesPrivateKey =
    AesPrivateKey


{-| OpaqueVariants
-}
type FileId
    = FileId Never


{-| OpaqueVariants
-}
type FileHash
    = FileHash String


sizeToString : Int -> String
sizeToString int =
    if int < 200 then
        String.fromInt int ++ " bytes"

    else if int < 1024 * 1024 then
        StringExtra.removeTrailing0s 1 (toFloat int / 1024) ++ "kb"

    else
        StringExtra.removeTrailing0s 1 (toFloat int / (1024 * 1024)) ++ "mb"


progressToString : { sent : Int, size : Int } -> String
progressToString { sent, size } =
    if size < 200 then
        String.fromInt sent ++ "/" ++ String.fromInt size ++ " bytes"

    else if size < 1024 * 1024 then
        StringExtra.removeTrailing0s 1 (toFloat sent / 1024) ++ "/" ++ StringExtra.removeTrailing0s 1 (toFloat size / 1024) ++ "kb"

    else
        StringExtra.removeTrailing0s 1 (toFloat sent / (1024 * 1024)) ++ "/" ++ StringExtra.removeTrailing0s 1 (toFloat size / (1024 * 1024)) ++ "mb"


fileUrl : ContentType -> FileHash -> String
fileUrl (ContentType contentType2) (FileHash fileHash2) =
    domain ++ "/file/" ++ String.fromInt contentType2 ++ "/" ++ fileHash2


thumbnailUrl : Coord CssPixels -> ContentType -> FileHash -> String
thumbnailUrl imageSize contentType2 (FileHash fileHash2) =
    if hasThumbnailImage imageSize then
        domain ++ "/file/t/" ++ fileHash2

    else
        fileUrl contentType2 (FileHash fileHash2)


hasThumbnailImage : Coord units -> Bool
hasThumbnailImage imageSize =
    Coord.yRaw imageSize > imageMaxHeight || Coord.xRaw imageSize > imageMaxHeight * 3


imageMaxHeight : number
imageMaxHeight =
    600


contentTypeType : ContentType -> ContentTypeType
contentTypeType contentType2 =
    case OneToOne.second contentType2 contentTypes of
        Just text ->
            if String.startsWith "image/" text then
                Image

            else if String.startsWith "text/" text then
                Text

            else if String.startsWith "video/" text then
                Video

            else if String.startsWith "audio/" text then
                Audio

            else if String.startsWith "application/" text then
                Application

            else
                Other

        Nothing ->
            Other


pngContent : ContentType
pngContent =
    contentType "image/png"


webpContent : ContentType
webpContent =
    contentType "image/webp"


gifContent : ContentType
gifContent =
    contentType "image/gif"


jsonContent : ContentType
jsonContent =
    contentType "application/json"


type ContentTypeType
    = Text
    | Image
    | Video
    | Audio
    | Application
    | Other


fileHash : String -> FileHash
fileHash =
    FileHash


{-| OpaqueVariants
-}
type ContentType
    = ContentType Int


contentType : String -> ContentType
contentType a =
    case String.split ";" a of
        head :: _ ->
            OneToOne.first (String.trim head) contentTypes |> Maybe.withDefault unknownContentType

        [] ->
            unknownContentType


unknownContentType : ContentType
unknownContentType =
    ContentType 9999


fileDataSerializeCodec : Serialize.Codec e FileData
fileDataSerializeCodec =
    Serialize.record FileData
        |> Serialize.field .fileName FileName.codec
        |> Serialize.field .fileSize Serialize.unsignedInt32
        |> Serialize.field .metadata (Serialize.maybe fileMetadataSerializeCodec)
        |> Serialize.field .contentType contentTypeSerializeCodec
        |> Serialize.field .fileHash fileHashSerializeCodec
        |> Serialize.field .isEncrypted isEncryptedSerializeCodec
        |> Serialize.finishRecord


fileHashSerializeCodec : Serialize.Codec e FileHash
fileHashSerializeCodec =
    Serialize.map FileHash (\(FileHash a) -> a) Serialize.string


contentTypeSerializeCodec : Serialize.Codec e ContentType
contentTypeSerializeCodec =
    Serialize.map ContentType (\(ContentType a) -> a) Serialize.unsignedInt16


isEncryptedSerializeCodec : Serialize.Codec e IsEncrypted
isEncryptedSerializeCodec =
    Serialize.customType
        (\isNotEncryptedEncoder isEncryptedEncoder value ->
            case value of
                IsNotEncrypted ->
                    isNotEncryptedEncoder

                IsEncrypted argA ->
                    isEncryptedEncoder argA
        )
        |> Serialize.variant0 IsNotEncrypted
        |> Serialize.variant1 IsEncrypted aesPrivateKeySerializeCodec
        |> Serialize.finishCustomType


aesPrivateKeySerializeCodec : Serialize.Codec e AesPrivateKey
aesPrivateKeySerializeCodec =
    Serialize.map AesPrivateKey (\(AesPrivateKey a) -> a) Serialize.bytes


fileMetadataSerializeCodec : Serialize.Codec e FileMetadata
fileMetadataSerializeCodec =
    Serialize.customType
        (\imageEncoder videoEncoder value ->
            case value of
                FileMetadata_Image argA ->
                    imageEncoder argA

                FileMetadata_Video argA ->
                    videoEncoder argA
        )
        |> Serialize.variant1 FileMetadata_Image imageMetadataSerializeCodec
        |> Serialize.variant1 FileMetadata_Video videoMetadataSerializeCodec
        |> Serialize.finishCustomType


imageMetadataSerializeCodec : Serialize.Codec e ImageMetadata
imageMetadataSerializeCodec =
    Serialize.record ImageMetadata
        |> Serialize.field .imageSize coordSerializeCodec
        |> Serialize.field .orientation (Serialize.maybe orientationSerializeCodec)
        |> Serialize.field .gpsLocation (Serialize.maybe locationSerializeCodec)
        |> Serialize.field .cameraOwner (Serialize.maybe Serialize.string)
        |> Serialize.field .exposureTime (Serialize.maybe exposureTimeSerializeCodec)
        |> Serialize.field .fNumber (Serialize.maybe Serialize.float)
        |> Serialize.field .focalLength (Serialize.maybe Serialize.float)
        |> Serialize.field .isoSpeedRating (Serialize.maybe Serialize.int)
        |> Serialize.field .make (Serialize.maybe Serialize.string)
        |> Serialize.field .model (Serialize.maybe Serialize.string)
        |> Serialize.field .software (Serialize.maybe Serialize.string)
        |> Serialize.field .userComment (Serialize.maybe Serialize.string)
        |> Serialize.finishRecord


videoMetadataSerializeCodec : Serialize.Codec e VideoMetadata
videoMetadataSerializeCodec =
    Serialize.record VideoMetadata
        |> Serialize.field .videoSize coordSerializeCodec
        |> Serialize.field .frames (Serialize.maybe (quantitySerializeCodec Serialize.int))
        |> Serialize.field .createdAt (Serialize.maybe posixSerializeCodec)
        |> Serialize.field .orientation orientationSerializeCodec
        |> Serialize.field .frameRate (Serialize.maybe (quantitySerializeCodec Serialize.float))
        |> Serialize.field .codec (Serialize.maybe Serialize.string)
        |> Serialize.field .title (Serialize.maybe Serialize.string)
        |> Serialize.field .gpsLocation (Serialize.maybe locationSerializeCodec)
        |> Serialize.finishRecord


orientationSerializeCodec : Serialize.Codec e Orientation
orientationSerializeCodec =
    Serialize.customType
        (\noChangeEncoder r90Encoder r180Encoder r270Encoder mirroredEncoder mr90Encoder mr180Encoder mr270Encoder value ->
            case value of
                NoChange ->
                    noChangeEncoder

                Rotation90 ->
                    r90Encoder

                Rotation180 ->
                    r180Encoder

                Rotation270 ->
                    r270Encoder

                Mirrored ->
                    mirroredEncoder

                MirroredRotation90 ->
                    mr90Encoder

                MirroredRotation180 ->
                    mr180Encoder

                MirroredRotation270 ->
                    mr270Encoder
        )
        |> Serialize.variant0 NoChange
        |> Serialize.variant0 Rotation90
        |> Serialize.variant0 Rotation180
        |> Serialize.variant0 Rotation270
        |> Serialize.variant0 Mirrored
        |> Serialize.variant0 MirroredRotation90
        |> Serialize.variant0 MirroredRotation180
        |> Serialize.variant0 MirroredRotation270
        |> Serialize.finishCustomType


locationSerializeCodec : Serialize.Codec e Location
locationSerializeCodec =
    Serialize.record Location
        |> Serialize.field .lat Serialize.float
        |> Serialize.field .lon Serialize.float
        |> Serialize.finishRecord


exposureTimeSerializeCodec : Serialize.Codec e ExposureTime
exposureTimeSerializeCodec =
    Serialize.record ExposureTime
        |> Serialize.field .numerator Serialize.int
        |> Serialize.field .denominator Serialize.int
        |> Serialize.finishRecord


coordSerializeCodec : Serialize.Codec e (Coord units)
coordSerializeCodec =
    Serialize.tuple (quantitySerializeCodec Serialize.int) (quantitySerializeCodec Serialize.int)


quantitySerializeCodec : Serialize.Codec e number -> Serialize.Codec e (Quantity number units)
quantitySerializeCodec number =
    Serialize.customType
        (\quantityEncoder value ->
            case value of
                Quantity.Quantity argA ->
                    quantityEncoder argA
        )
        |> Serialize.variant1 Quantity.Quantity number
        |> Serialize.finishCustomType


posixSerializeCodec : Serialize.Codec e Time.Posix
posixSerializeCodec =
    Serialize.map Time.millisToPosix Time.posixToMillis Serialize.int


type alias UploadResponse =
    { fileHash : FileHash
    , imageMetadata : Maybe ImageMetadata
    , videoMetadata : Maybe VideoMetadata
    }


uploadResponseCodec : Codec UploadResponse
uploadResponseCodec =
    Codec.object UploadResponse
        |> Codec.field "hash" .fileHash fileHashCodec
        |> Codec.field "image_metadata" .imageMetadata (Codec.nullable imageMetadataCodec)
        |> Codec.field "video_metadata" .videoMetadata (Codec.nullable videoMetadataCodec)
        |> Codec.buildObject


fileHashCodec : Codec FileHash
fileHashCodec =
    Codec.map fileHash (\(FileHash a) -> a) Codec.string


imageMetadataCodec : Codec ImageMetadata
imageMetadataCodec =
    Codec.object ImageMetadata
        |> Codec.field "image_size" .imageSize (Codec.tuple CodecExtra.quantityInt CodecExtra.quantityInt)
        |> Codec.field "orientation" .orientation (Codec.nullable orientationCodec)
        |> Codec.field "gps_location" .gpsLocation (Codec.nullable locationCodec)
        |> Codec.field "camera_owner" .cameraOwner (Codec.nullable Codec.string)
        |> Codec.field "exposure_time" .exposureTime (Codec.nullable exposureTimeCodec)
        |> Codec.field "f_number" .fNumber (Codec.nullable Codec.float)
        |> Codec.field "focal_length" .focalLength (Codec.nullable Codec.float)
        |> Codec.field "iso_speed_rating" .isoSpeedRating (Codec.nullable Codec.int)
        |> Codec.field "make" .make (Codec.nullable Codec.string)
        |> Codec.field "model" .model (Codec.nullable Codec.string)
        |> Codec.field "software" .software (Codec.nullable Codec.string)
        |> Codec.field "user_comment" .userComment (Codec.nullable Codec.string)
        |> Codec.buildObject


locationCodec : Codec Location
locationCodec =
    Codec.object Location
        |> Codec.field "lat" .lat Codec.float
        |> Codec.field "lon" .lon Codec.float
        |> Codec.buildObject


exposureTimeCodec : Codec ExposureTime
exposureTimeCodec =
    Codec.object ExposureTime
        |> Codec.field "numerator" .numerator Codec.int
        |> Codec.field "denominator" .denominator Codec.int
        |> Codec.buildObject


type alias ImageMetadata =
    { imageSize : Coord CssPixels
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
    { -- The size the video is displayed at, with any rotation already applied.
      videoSize : Coord CssPixels
    , frames : Maybe (Quantity Int VideoFrames)
    , createdAt : Maybe Time.Posix
    , orientation : Orientation
    , frameRate : Maybe (Quantity Float (Rate VideoFrames Seconds))
    , codec : Maybe String
    , title : Maybe String
    , gpsLocation : Maybe Location
    }


videoMetadataCodec : Codec VideoMetadata
videoMetadataCodec =
    Codec.object VideoMetadata
        |> Codec.field "video_size" .videoSize (Codec.tuple CodecExtra.quantityInt CodecExtra.quantityInt)
        |> Codec.field "frames" .frames (Codec.nullable CodecExtra.quantityInt)
        |> Codec.field "created_at_ms" .createdAt (Codec.nullable CodecExtra.time)
        |> Codec.field "orientation" .orientation orientationCodec
        |> Codec.field "frame_rate" .frameRate (Codec.nullable CodecExtra.quantityFloat)
        |> Codec.field "codec" .codec (Codec.nullable Codec.string)
        |> Codec.field "title" .title (Codec.nullable Codec.string)
        |> Codec.field "gps_location" .gpsLocation (Codec.nullable locationCodec)
        |> Codec.buildObject



--pub struct VideoMetadata {
--    /// The size the video is displayed at, with any rotation already applied.
--    pub video_size: (u32, u32),
--    pub duration_ms: Option<u64>,
--    /// When the file says it was recorded, as milliseconds since the Unix epoch.
--    pub created_at_ms: Option<i64>,
--    /// A quarter turn or half turn the video is displayed with, in degrees. Only
--    /// `MP4` stores this; it is already applied to `video_size`.
--    pub rotation: Option<u16>,
--    pub frame_rate: Option<f32>,
--    /// How the container names the video codec. `MP4` files use the RFC 6381
--    /// spelling such as `avc1.42E01E`, Matroska files their own such as `V_VP9`.
--    pub codec: Option<String>,
--    pub title: Option<String>,
--}


type Orientation
    = NoChange
    | Rotation90
    | Rotation180
    | Rotation270
    | Mirrored
    | MirroredRotation90
    | MirroredRotation180
    | MirroredRotation270


orientationCodec : Codec Orientation
orientationCodec =
    Codec.andThen
        (\a ->
            case a of
                1 ->
                    Codec.succeed NoChange

                8 ->
                    Codec.succeed Rotation90

                3 ->
                    Codec.succeed Rotation180

                6 ->
                    Codec.succeed Rotation270

                2 ->
                    Codec.succeed Mirrored

                5 ->
                    Codec.succeed MirroredRotation90

                4 ->
                    Codec.succeed MirroredRotation180

                7 ->
                    Codec.succeed MirroredRotation270

                _ ->
                    Codec.fail "Invalid orientation"
        )
        (\a ->
            case a of
                NoChange ->
                    1

                Rotation90 ->
                    8

                Rotation180 ->
                    3

                Rotation270 ->
                    6

                Mirrored ->
                    2

                MirroredRotation90 ->
                    5

                MirroredRotation180 ->
                    4

                MirroredRotation270 ->
                    7
        )
        Codec.int


type alias Location =
    { lat : Float, lon : Float }


type alias ExposureTime =
    { numerator : Int, denominator : Int }


{-| Header name needs to stay in sync with Rust code
-}
secretKeyHeader : SecretId ServerSecret -> Http.Header
secretKeyHeader secretKey =
    Http.header "x-secret-key" (SecretId.toString secretKey)


{-| Backend initiated, so there is no browser and no cookie. The server secret
is what tells the Rust server this came from us.
-}
uploadUrl : SecretId ServerSecret -> String -> Task restriction Http.Error UploadResponse
uploadUrl secretKey url =
    Http.task
        { method = "POST"
        , headers = [ secretKeyHeader secretKey ]
        , url = domain ++ "/file/internal/upload-url"
        , body = Http.jsonBody (Codec.encodeToValue uploadUrlCodec { url = url })
        , resolver = resolver uploadResponseCodec
        , timeout = Just (Duration.seconds 30)
        }


discordStickerUrl : Discord.Id Discord.StickerId -> Discord.StickerFormatType -> String
discordStickerUrl stickerId format =
    domain
        ++ "/file/discord-sticker/"
        ++ Discord.idToString stickerId
        ++ (case format of
                Discord.PngFormat ->
                    ".png"

                Discord.ApngFormat ->
                    ".png"

                Discord.LottieFormat ->
                    ".json"

                Discord.GifFormat ->
                    ".gif"
           )


type alias UploadUrlRequest =
    { url : String }


uploadUrlCodec : Codec UploadUrlRequest
uploadUrlCodec =
    Codec.object UploadUrlRequest
        |> Codec.field "url" .url Codec.string
        |> Codec.buildObject


{-| Uploads are authenticated by the `sid` cookie, which the browser attaches on
its own. `riskyRequest` is what sets `withCredentials`, and without it the
browser withholds cookies from `localhost:3000` when the page is served from
`localhost:8000`. In production both are at-chat.app, so the cookie would be
sent either way.
-}
uploadFile :
    (Result Http.Error UploadResponse -> msg)
    -> ( AnyGuildOrDmId, ThreadRoute )
    -> Id FileId
    -> File
    -> Command restriction toFrontend msg
uploadFile onResult guildOrDmId fileId file2 =
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = domain ++ "/file/upload"
        , body = Http.fileBody file2
        , expect = Http.expectJson onResult (Codec.decoder uploadResponseCodec)
        , timeout = Just Duration.minute
        , tracker = uploadTrackerId guildOrDmId fileId |> Just
        }


{-| The already encrypted bytes of a file being attached to an end-to-end encrypted DM.
The browser has no `File` to hand over here, only the ciphertext Elm got back from it, so
the name and type the server would otherwise read off the file are lost. Neither is
missed: both are recorded on this device and travel inside the encrypted message instead.
-}
uploadEncryptedFile :
    (Result Http.Error UploadResponse -> msg)
    -> ( AnyGuildOrDmId, ThreadRoute )
    -> Id FileId
    -> Bytes
    -> Command restriction toFrontend msg
uploadEncryptedFile onResult guildOrDmId fileId cipherText =
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = domain ++ "/file/upload"
        , body = Http.bytesBody "application/octet-stream" cipherText
        , expect = Http.expectJson onResult (Codec.decoder uploadResponseCodec)
        , timeout = Just Duration.minute
        , tracker = uploadTrackerId guildOrDmId fileId |> Just
        }


{-| A file being attached to a game rather than to a message. Games keep their attachments
outside of `filesToUpload`, so the caller says what to track this upload as and nothing
cancels the wrong one.
-}
uploadGameFile :
    (Result Http.Error UploadResponse -> msg)
    -> String
    -> File
    -> Command restriction toFrontend msg
uploadGameFile onResult trackerId file2 =
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = domain ++ "/file/upload"
        , body = Http.fileBody file2
        , expect = Http.expectJson onResult (Codec.decoder uploadResponseCodec)
        , timeout = Just Duration.minute
        , tracker = Just trackerId
        }


uploadString :
    (Result Http.Error UploadResponse -> msg)
    -> ( AnyGuildOrDmId, ThreadRoute )
    -> Id FileId
    -> String
    -> Command restriction toFrontend msg
uploadString onResult guildOrDmId fileId text =
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = domain ++ "/file/upload"
        , body = Http.stringBody "text/plain" text
        , expect = Http.expectJson onResult (Codec.decoder uploadResponseCodec)
        , timeout = Just Duration.minute
        , tracker = uploadTrackerId guildOrDmId fileId |> Just
        }


uploadAvatar :
    (Result Http.Error UploadResponse -> msg)
    -> Bytes
    -> Command restriction toFrontend msg
uploadAvatar onResult file2 =
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = domain ++ "/file/upload"
        , body = Http.bytesBody "application/octet-stream" file2
        , expect = Http.expectJson onResult (Codec.decoder uploadResponseCodec)
        , timeout = Just Duration.minute
        , tracker = Just "avatar-file-upload"
        }


uploadTrackerId : ( AnyGuildOrDmId, ThreadRoute ) -> Id FileId -> String
uploadTrackerId ( guildOrDmId, threadRoute ) fileId =
    (case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }) ->
            Id.toString guildId
                ++ ","
                ++ Id.toString channelId

        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
            Id.toString otherUserId

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild id) ->
            "d"
                ++ Discord.idToString id.guildId
                ++ ","
                ++ Discord.idToString id.channelId

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId, channelId }) ->
            "dd"
                ++ Discord.idToString currentUserId
                ++ ","
                ++ Discord.idToString channelId
    )
        ++ (case threadRoute of
                ViewThread threadMessageIndex ->
                    ",t" ++ Id.toString threadMessageIndex

                NoThread ->
                    ""
           )
        ++ "f"
        ++ Id.toString fileId


uploadBytes : SecretId ServerSecret -> Bytes -> Task restriction Http.Error UploadResponse
uploadBytes secretKey bytes =
    Http.task
        { method = "POST"
        , headers = [ secretKeyHeader secretKey ]
        , url = domain ++ "/file/upload"
        , body = Http.bytesBody "application/octet-stream" bytes
        , resolver = resolver uploadResponseCodec
        , timeout = Just Duration.minute
        }


uploadBackup : SecretId ServerSecret -> String -> Bytes -> Task BackendOnly Http.Error ()
uploadBackup secretKey name bytes =
    Http.task
        { method = "POST"
        , headers = [ secretKeyHeader secretKey ]
        , url = domain ++ "/file/internal/upload-backup/" ++ name
        , body = Http.bytesBody "application/octet-stream" bytes
        , resolver =
            Http.stringResolver
                (\result ->
                    case result of
                        Http.GoodStatus_ _ _ ->
                            Ok ()

                        Http.BadUrl_ string ->
                            Err (Http.BadUrl string)

                        Http.Timeout_ ->
                            Err Http.Timeout

                        Http.NetworkError_ ->
                            Err Http.NetworkError

                        Http.BadStatus_ metadata text ->
                            "Status code: "
                                ++ String.fromInt metadata.statusCode
                                ++ " Message: "
                                ++ text
                                |> Http.BadBody
                                |> Err
                )
        , timeout = Just Duration.minute
        }


resolver : Codec value -> Http.Resolver restriction Http.Error value
resolver codec =
    Http.stringResolver
        (\result ->
            case result of
                Http.GoodStatus_ _ text ->
                    case Codec.decodeString codec text of
                        Ok ok ->
                            Ok ok

                        Err error ->
                            Json.Decode.errorToString error |> Http.BadBody |> Err

                Http.BadUrl_ string ->
                    Err (Http.BadUrl string)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata _ ->
                    Err (Http.BadStatus metadata.statusCode)
        )


domain : String
domain =
    if Env.isProduction then
        Env.domain

    else
        "http://localhost:3000"


{-| The rust server's websocket endpoints are on the same server as its file
endpoints, so the address is the same one with a websocket scheme. Deriving it
rather than writing it out is what stops the two drifting apart.
-}
websocketDomain : String
websocketDomain =
    String.replace "http" "ws" domain


imageInfoView : Time.Zone -> msg -> FileDataWithImage -> Element msg
imageInfoView timezone onPressClose fileData =
    Ui.el
        [ Ui.inFront
            (MyUi.elButton
                (Dom.id "fileStatus_closeImageInfo")
                onPressClose
                [ Ui.alignRight
                , Ui.paddingXY 16 16
                , MyUi.htmlStyle "transform" ("translateY(" ++ MyUi.insetTop ++ ")")
                , MyUi.hoverText "Close"
                ]
                (Ui.html Icons.x)
            )
        ]
        (case fileData.metadata of
            FileMetadata_Image metadata ->
                infoPanel
                    [ Ui.column
                        [ Ui.spacing 2
                        , Ui.alignBottom
                        , Ui.paddingXY 8 0
                        ]
                        (imageLabel
                            "Image size"
                            (String.fromInt (Coord.xRaw metadata.imageSize) ++ "×" ++ String.fromInt (Coord.yRaw metadata.imageSize))
                            :: List.filterMap
                                identity
                                [ Maybe.map (\orientation -> imageLabel "Orientation" (orientationToString orientation)) metadata.orientation
                                , Maybe.map (\location -> imageLabel "Location" (locationToString location)) metadata.gpsLocation
                                , Maybe.map (imageLabel "Camera owner") metadata.cameraOwner
                                , Maybe.map (\exposure -> imageLabel "Exposure time" (exposureTimeToString exposure)) metadata.exposureTime
                                , Maybe.map (\fNumber -> imageLabel "F-number" ("f/" ++ String.fromFloat fNumber)) metadata.fNumber
                                , Maybe.map (\focal -> imageLabel "Focal length" (String.fromFloat focal ++ "mm")) metadata.focalLength
                                , Maybe.map (\iso -> imageLabel "ISO" (String.fromInt iso)) metadata.isoSpeedRating
                                , Maybe.map (imageLabel "Make") metadata.make
                                , Maybe.map (imageLabel "Model") metadata.model
                                , Maybe.map (imageLabel "Software") metadata.software
                                , Maybe.map (imageLabel "Comment") metadata.userComment
                                ]
                        )
                    , Ui.image
                        [ Ui.widthMax (Coord.xRaw metadata.imageSize), Ui.centerX ]
                        { source = fileUrl fileData.contentType fileData.fileHash
                        , description = ""
                        , onLoad = Nothing
                        }
                    ]

            FileMetadata_Video metadata ->
                infoPanel
                    [ Ui.column
                        [ Ui.spacing 2
                        , Ui.alignBottom
                        , Ui.paddingXY 8 0
                        ]
                        (imageLabel
                            "Video size"
                            (String.fromInt (Coord.xRaw metadata.videoSize) ++ "×" ++ String.fromInt (Coord.yRaw metadata.videoSize))
                            :: List.filterMap
                                identity
                                [ Maybe.map (imageLabel "Title") metadata.title
                                , Maybe.map (\duration -> imageLabel "Duration" (durationToString duration)) (videoDuration metadata)
                                , Maybe.map (\frames -> imageLabel "Frames" (String.fromInt (Quantity.unwrap frames))) metadata.frames
                                , Maybe.map (\frameRate -> imageLabel "Frame rate" (frameRateToString frameRate)) metadata.frameRate

                                -- Every video has an orientation, and almost every
                                -- one of them is the uninteresting answer.
                                , if metadata.orientation == NoChange then
                                    Nothing

                                  else
                                    Just (imageLabel "Orientation" (orientationToString metadata.orientation))
                                , Maybe.map (imageLabel "Codec") metadata.codec
                                , Maybe.map (\time -> imageLabel "Recorded" (MyUi.datestamp timezone time ++ " " ++ MyUi.timestamp time timezone)) metadata.createdAt
                                , Maybe.map (\location -> imageLabel "Location" (locationToString location)) metadata.gpsLocation
                                ]
                        )
                    , Ui.el
                        [ Ui.widthMax (Coord.xRaw metadata.videoSize), Ui.centerX ]
                        (Ui.html
                            (Html.video
                                [ Html.Attributes.src (fileUrl fileData.contentType fileData.fileHash)
                                , Html.Attributes.controls True
                                , Html.Attributes.style "display" "block"
                                , Html.Attributes.style "width" "100%"
                                ]
                                []
                            )
                        )
                    ]
        )


{-| The scrolling panel both kinds of file info are laid out inside.
-}
infoPanel : List (Element msg) -> Element msg
infoPanel contents =
    Ui.column
        [ Ui.height Ui.fill
        , Ui.scrollable
        , Ui.heightMin 0
        , Ui.background MyUi.background1
        , MyUi.htmlStyle "padding" ("calc(" ++ MyUi.insetTop ++ " + 16px) 0px " ++ MyUi.insetBottom ++ " 0px")
        , Ui.spacing 16
        ]
        contents


{-| Neither container writes down how long the video runs, so this works it out
from the two things they do write down.
-}
videoDuration : VideoMetadata -> Maybe Duration
videoDuration metadata =
    Maybe.map2
        (\frames frameRate -> Quantity.at_ frameRate (Quantity.toFloatQuantity frames))
        metadata.frames
        metadata.frameRate


durationToString : Duration -> String
durationToString duration =
    let
        total : Int
        total =
            round (Duration.inSeconds duration)

        pad : Int -> String
        pad value =
            String.padLeft 2 '0' (String.fromInt value)
    in
    if total >= 3600 then
        String.fromInt (total // 3600) ++ ":" ++ pad (modBy 60 (total // 60)) ++ ":" ++ pad (modBy 60 total)

    else
        String.fromInt (total // 60) ++ ":" ++ pad (modBy 60 total)


frameRateToString : Quantity Float (Rate VideoFrames Seconds) -> String
frameRateToString frameRate =
    StringExtra.removeTrailing0s 2 (Quantity.unwrap frameRate) ++ " fps"


imageLabel : String -> String -> Element msg
imageLabel title value =
    Ui.row
        [ MyUi.htmlStyle "white-space" "pre-wrap" ]
        [ Ui.text (title ++ ": ")
        , Ui.text value
        ]


orientationToString : Orientation -> String
orientationToString orientation =
    case orientation of
        NoChange ->
            "Normal"

        Rotation90 ->
            "Rotate 90°"

        Rotation180 ->
            "Rotate 180°"

        Rotation270 ->
            "Rotate 270°"

        Mirrored ->
            "Mirrored"

        MirroredRotation90 ->
            "Mirrored, rotate 90°"

        MirroredRotation180 ->
            "Mirrored, rotate 180°"

        MirroredRotation270 ->
            "Mirrored, rotate 270°"


locationToString : Location -> String
locationToString location =
    String.fromFloat location.lat ++ ", " ++ String.fromFloat location.lon


exposureTimeToString : ExposureTime -> String
exposureTimeToString exposure =
    if exposure.numerator == 1 then
        "1/" ++ String.fromInt exposure.denominator ++ "s"

    else
        String.fromInt exposure.numerator ++ "/" ++ String.fromInt exposure.denominator ++ "s"


imageHasMetadata : ImageMetadata -> Bool
imageHasMetadata metadata =
    (metadata.orientation /= Nothing)
        || (metadata.gpsLocation /= Nothing)
        || (metadata.cameraOwner /= Nothing)
        || (metadata.exposureTime /= Nothing)
        || (metadata.fNumber /= Nothing)
        || (metadata.focalLength /= Nothing)
        || (metadata.isoSpeedRating /= Nothing)
        || (metadata.make /= Nothing)
        || (metadata.model /= Nothing)
        || (metadata.software /= Nothing)
        || (metadata.userComment /= Nothing)


videoHasMetadata : VideoMetadata -> Bool
videoHasMetadata metadata =
    (metadata.frames /= Nothing)
        || (metadata.createdAt /= Nothing)
        || (metadata.orientation /= NoChange)
        || (metadata.codec /= Nothing)
        || (metadata.title /= Nothing)


addFileHash : Result Http.Error UploadResponse -> FileStatus -> FileStatus
addFileHash result fileStatus =
    case fileStatus of
        FileUploading fileName fileSize contentType2 isEncrypted ->
            case result of
                Ok data ->
                    FileUploaded
                        { fileName = fileName
                        , fileSize = fileSize.size
                        , metadata = uploadResponseMetadata data
                        , contentType = contentType2
                        , fileHash = data.fileHash
                        , isEncrypted = isEncrypted
                        }

                Err error ->
                    FileError fileName fileSize.size contentType2 error isEncrypted

        FileUploaded _ ->
            fileStatus

        FileError _ _ _ _ _ ->
            fileStatus


uploadResponseMetadata : UploadResponse -> Maybe FileMetadata
uploadResponseMetadata data =
    case ( data.imageMetadata, data.videoMetadata ) of
        ( Just imageMetadata, Nothing ) ->
            FileMetadata_Image imageMetadata |> Just

        ( _, Just videoMetadata ) ->
            FileMetadata_Video videoMetadata |> Just

        ( Nothing, Nothing ) ->
            Nothing


onlyUploadedFiles : SeqDict (Id FileId) FileStatus -> SeqDict (Id FileId) FileData
onlyUploadedFiles dict =
    SeqDict.filterMap
        (\_ status ->
            case status of
                FileUploading _ _ _ _ ->
                    Nothing

                FileUploaded fileData ->
                    Just fileData

                FileError _ _ _ _ _ ->
                    Nothing
        )
        dict


hasUploadingFile : SeqDict (Id FileId) FileStatus -> Bool
hasUploadingFile dict =
    SeqDict.toList dict
        |> List.any
            (\( _, status ) ->
                case status of
                    FileUploading _ _ _ _ ->
                        True

                    FileUploaded _ ->
                        False

                    FileError _ _ _ _ _ ->
                        False
            )


{-| List found here <https://mimetype.io/all-types>. Keep list in sync with rust-server/src/main.rs
-}
contentTypes : OneToOne ContentType String
contentTypes =
    [ "image/gif"
    , "image/jpeg"
    , "image/png"
    , "image/webp"
    , "text/plain"
    , "text/calendar"
    , "text/css"
    , "text/csv"
    , "text/html"
    , "text/javascript"
    , "text/markdown"
    , "text/mathml"
    , "text/prs.lines.tag"
    , "text/richtext"
    , "text/sgml"
    , "text/tab-separated-values"
    , "text/troff"
    , "text/uri-list"
    , "text/vnd.curl"
    , "text/vnd.curl.dcurl"
    , "text/vnd.curl.mcurl"
    , "text/vnd.curl.scurl"
    , "text/vnd.fly"
    , "text/vnd.fmi.flexstor"
    , "text/vnd.graphviz"
    , "text/vnd.in3d.3dml"
    , "text/vnd.in3d.spot"
    , "text/vnd.sun.j2me.app-descriptor"
    , "text/vnd.wap.si"
    , "text/vnd.wap.sl"
    , "text/vnd.wap.wml"
    , "text/vnd.wap.wmlscript"
    , "text/x-asm"
    , "text/x-c"
    , "text/x-fortran"
    , "text/x-java-source"
    , "text/x-pascal"
    , "text/x-python"
    , "text/x-setext"
    , "text/x-uuencode"
    , "text/x-vcalendar"
    , "text/x-vcard"
    , "video/3gpp"
    , "video/3gpp2"
    , "video/h261"
    , "video/h263"
    , "video/h264"
    , "video/jpeg"
    , "video/jpm"
    , "video/mj2"
    , "video/mp2t"
    , "video/mp4"
    , "video/mpeg"
    , "video/ogg"
    , "video/quicktime"
    , "video/vnd.fvt"
    , "video/vnd.mpegurl"
    , "video/vnd.ms-playready.media.pyv"
    , "video/vnd.vivo"
    , "video/webm"
    , "video/x-f4v"
    , "video/x-fli"
    , "video/x-flv"
    , "video/x-m4v"
    , "video/x-matroska"
    , "video/x-ms-asf"
    , "video/x-ms-wm"
    , "video/x-ms-wmv"
    , "video/x-ms-wmx"
    , "video/x-ms-wvx"
    , "video/x-msvideo"
    , "video/x-sgi-movie"
    , "audio/3gpp2"
    , "audio/aac"
    , "audio/aacp"
    , "audio/adpcm"
    , "audio/aiff"
    , "audio/x-aiff"
    , "audio/basic"
    , "audio/flac"
    , "audio/midi"
    , "audio/mp4"
    , "audio/mp4a-latm"
    , "audio/mpeg"
    , "audio/ogg"
    , "audio/opus"
    , "audio/vnd.digital-winds"
    , "audio/vnd.dts"
    , "audio/vnd.dts.hd"
    , "audio/vnd.lucent.voice"
    , "audio/vnd.ms-playready.media.pya"
    , "audio/vnd.nuera.ecelp4800"
    , "audio/vnd.nuera.ecelp7470"
    , "audio/vnd.nuera.ecelp9600"
    , "audio/vnd.wav"
    , "audio/wav"
    , "audio/x-wav"
    , "audio/vnd.wave"
    , "audio/wave"
    , "audio/webm"
    , "audio/x-pn-wav"
    , "audio/x-matroska"
    , "audio/x-mpegurl"
    , "audio/x-ms-wax"
    , "audio/x-ms-wma"
    , "audio/x-pn-realaudio"
    , "audio/x-pn-realaudio-plugin"
    , "application/andrew-inset"
    , "application/applixware"
    , "application/atom+xml"
    , "application/atomcat+xml"
    , "application/atomsvc+xml"
    , "application/ccxml+xml"
    , "application/cu-seeme"
    , "application/davmount+xml"
    , "application/ecmascript"
    , "application/emma+xml"
    , "application/epub+zip"
    , "application/font-tdpfr"
    , "application/gzip"
    , "application/hyperstudio"
    , "application/java-archive"
    , "application/java-serialized-object"
    , "application/java-vm"
    , "application/json"
    , "application/lost+xml"
    , "application/mac-binhex40"
    , "application/mac-compactpro"
    , "application/marc"
    , "application/mathematica"
    , "application/mathml+xml"
    , "application/mbox"
    , "application/mediaservercontrol+xml"
    , "application/mp4"
    , "application/msword"
    , "application/mxf"
    , "application/octet-stream"
    , "application/oda"
    , "application/oebps-package+xml"
    , "application/ogg"
    , "application/onenote"
    , "application/patch-ops-error+xml"
    , "application/pdf"
    , "application/pgp-encrypted"
    , "application/pgp-signature"
    , "application/pics-rules"
    , "application/pkcs10"
    , "application/pkcs7-mime"
    , "application/pkcs7-signature"
    , "application/pkix-cert"
    , "application/pkix-crl"
    , "application/pkix-pkipath"
    , "application/pkixcmp"
    , "application/pls+xml"
    , "application/postscript"
    , "application/prql"
    , "application/prs.cww"
    , "application/rdf+xml"
    , "application/reginfo+xml"
    , "application/relax-ng-compact-syntax"
    , "application/resource-lists+xml"
    , "application/resource-lists-diff+xml"
    , "application/rls-services+xml"
    , "application/rsd+xml"
    , "application/rss+xml"
    , "application/rtf"
    , "application/sbml+xml"
    , "application/scvp-cv-request"
    , "application/scvp-cv-response"
    , "application/scvp-vp-request"
    , "application/scvp-vp-response"
    , "application/sdp"
    , "application/set-payment-initiation"
    , "application/set-registration-initiation"
    , "application/shf+xml"
    , "application/smil+xml"
    , "application/sparql-query"
    , "application/sparql-results+xml"
    , "application/srgs"
    , "application/srgs+xml"
    , "application/ssml+xml"
    , "application/vnd.3gpp.pic-bw-large"
    , "application/vnd.3gpp.pic-bw-small"
    , "application/vnd.3gpp.pic-bw-var"
    , "application/vnd.3gpp2.tcap"
    , "application/vnd.3m.post-it-notes"
    , "application/vnd.accpac.simply.aso"
    , "application/vnd.accpac.simply.imp"
    , "application/vnd.acucobol"
    , "application/vnd.acucorp"
    , "application/vnd.adobe.air-application-installer-package+zip"
    , "application/vnd.adobe.xdp+xml"
    , "application/vnd.adobe.xfdf"
    , "application/vnd.airzip.filesecure.azf"
    , "application/vnd.airzip.filesecure.azs"
    , "application/vnd.amazon.ebook"
    , "application/vnd.americandynamics.acc"
    , "application/vnd.amiga.ami"
    , "application/vnd.android.package-archive"
    , "application/vnd.anser-web-certificate-issue-initiation"
    , "application/vnd.anser-web-funds-transfer-initiation"
    , "application/vnd.antix.game-component"
    , "application/vnd.apple.installer+xml"
    , "application/vnd.arastra.swi"
    , "application/vnd.audiograph"
    , "application/vnd.blueice.multipass"
    , "application/vnd.bmi"
    , "application/vnd.businessobjects"
    , "application/vnd.chemdraw+xml"
    , "application/vnd.chipnuts.karaoke-mmd"
    , "application/vnd.cinderella"
    , "application/vnd.claymore"
    , "application/vnd.clonk.c4group"
    , "application/vnd.commonspace"
    , "application/vnd.contact.cmsg"
    , "application/vnd.cosmocaller"
    , "application/vnd.crick.clicker"
    , "application/vnd.crick.clicker.keyboard"
    , "application/vnd.crick.clicker.palette"
    , "application/vnd.crick.clicker.template"
    , "application/vnd.crick.clicker.wordbank"
    , "application/vnd.criticaltools.wbs+xml"
    , "application/vnd.ctc-posml"
    , "application/vnd.cups-ppd"
    , "application/vnd.curl.car"
    , "application/vnd.curl.pcurl"
    , "application/vnd.data-vision.rdz"
    , "application/vnd.debian.binary-package"
    , "application/vnd.denovo.fcselayout-link"
    , "application/vnd.dna"
    , "application/vnd.dolby.mlp"
    , "application/vnd.dpgraph"
    , "application/vnd.dreamfactory"
    , "application/vnd.dynageo"
    , "application/vnd.ecowin.chart"
    , "application/vnd.enliven"
    , "application/vnd.epson.esf"
    , "application/vnd.epson.msf"
    , "application/vnd.epson.quickanime"
    , "application/vnd.epson.salt"
    , "application/vnd.epson.ssf"
    , "application/vnd.eszigno3+xml"
    , "application/vnd.ezpix-album"
    , "application/vnd.ezpix-package"
    , "application/vnd.fdf"
    , "application/vnd.fdsn.mseed"
    , "application/vnd.fdsn.seed"
    , "application/vnd.flographit"
    , "application/vnd.fluxtime.clip"
    , "application/vnd.framemaker"
    , "application/vnd.frogans.fnc"
    , "application/vnd.frogans.ltf"
    , "application/vnd.fsc.weblaunch"
    , "application/vnd.fujitsu.oasys"
    , "application/vnd.fujitsu.oasys2"
    , "application/vnd.fujitsu.oasys3"
    , "application/vnd.fujitsu.oasysgp"
    , "application/vnd.fujitsu.oasysprs"
    , "application/vnd.fujixerox.ddd"
    , "application/vnd.fujixerox.docuworks"
    , "application/vnd.fujixerox.docuworks.binder"
    , "application/vnd.fuzzysheet"
    , "application/vnd.genomatix.tuxedo"
    , "application/vnd.geogebra.file"
    , "application/vnd.geogebra.tool"
    , "application/vnd.geometry-explorer"
    , "application/vnd.gerber"
    , "application/vnd.gmx"
    , "application/vnd.google-earth.kml+xml"
    , "application/vnd.google-earth.kmz"
    , "application/vnd.grafeq"
    , "application/vnd.groove-account"
    , "application/vnd.groove-help"
    , "application/vnd.groove-identity-message"
    , "application/vnd.groove-injector"
    , "application/vnd.groove-tool-message"
    , "application/vnd.groove-tool-template"
    , "application/vnd.groove-vcard"
    , "application/vnd.handheld-entertainment+xml"
    , "application/vnd.hbci"
    , "application/vnd.hhe.lesson-player"
    , "application/vnd.hp-hpgl"
    , "application/vnd.hp-hpid"
    , "application/vnd.hp-hps"
    , "application/vnd.hp-jlyt"
    , "application/vnd.hp-pcl"
    , "application/vnd.hp-pclxl"
    , "application/vnd.hydrostatix.sof-data\t.sf"
    , "application/vnd.hzn-3d-crossword"
    , "application/vnd.ibm.minipay"
    , "application/vnd.ibm.modcap"
    , "application/vnd.ibm.rights-management"
    , "application/vnd.ibm.secure-container"
    , "application/vnd.iccprofile"
    , "application/vnd.igloader"
    , "application/vnd.immervision-ivp"
    , "application/vnd.immervision-ivu"
    , "application/vnd.intercon.formnet"
    , "application/vnd.intu.qbo"
    , "application/vnd.intu.qfx"
    , "application/vnd.ipunplugged.rcprofile"
    , "application/vnd.irepository.package+xml"
    , "application/vnd.is-xpr"
    , "application/vnd.jam"
    , "application/vnd.jcp.javame.midlet-rms"
    , "application/vnd.jisp"
    , "application/vnd.joost.joda-archive"
    , "application/vnd.kahootz"
    , "application/vnd.kde.karbon"
    , "application/vnd.kde.kchart"
    , "application/vnd.kde.kformula"
    , "application/vnd.kde.kivio"
    , "application/vnd.kde.kontour"
    , "application/vnd.kde.kpresenter"
    , "application/vnd.kde.kspread"
    , "application/vnd.kde.kword"
    , "application/vnd.kenameaapp"
    , "application/vnd.kidspiration"
    , "application/vnd.kinar"
    , "application/vnd.koan"
    , "application/vnd.kodak-descriptor"
    , "application/vnd.llamagraphics.life-balance.desktop"
    , "application/vnd.llamagraphics.life-balance.exchange+xml"
    , "application/vnd.lotus-1-2-3"
    , "application/vnd.lotus-approach"
    , "application/vnd.lotus-freelance"
    , "application/vnd.lotus-notes"
    , "application/vnd.lotus-organizer"
    , "application/vnd.lotus-screencam"
    , "application/vnd.lotus-wordpro"
    , "application/vnd.macports.portpkg"
    , "application/vnd.mcd"
    , "application/vnd.medcalcdata"
    , "application/vnd.mediastation.cdkey"
    , "application/vnd.mfer"
    , "application/vnd.mfmp"
    , "application/vnd.micrografx.flo"
    , "application/vnd.micrografx.igx"
    , "application/vnd.mif"
    , "application/vnd.mobius.daf"
    , "application/vnd.mobius.dis"
    , "application/vnd.mobius.mbk"
    , "application/vnd.mobius.mqy"
    , "application/vnd.mobius.msl"
    , "application/vnd.mobius.plc"
    , "application/vnd.mobius.txf"
    , "application/vnd.mophun.application"
    , "application/vnd.mophun.certificate"
    , "application/vnd.mozilla.xul+xml"
    , "application/vnd.ms-artgalry"
    , "application/vnd.ms-cab-compressed"
    , "application/vnd.ms-excel"
    , "application/vnd.ms-excel.addin.macroenabled.12"
    , "application/vnd.ms-excel.sheet.binary.macroenabled.12"
    , "application/vnd.ms-excel.sheet.macroenabled.12"
    , "application/vnd.ms-excel.template.macroenabled.12"
    , "application/vnd.ms-fontobject"
    , "application/vnd.ms-htmlhelp"
    , "application/vnd.ms-ims"
    , "application/vnd.ms-lrm"
    , "application/vnd.ms-pki.seccat"
    , "application/vnd.ms-pki.stl"
    , "application/vnd.ms-powerpoint"
    , "application/vnd.ms-powerpoint.addin.macroenabled.12"
    , "application/vnd.ms-powerpoint.presentation.macroenabled.12"
    , "application/vnd.ms-powerpoint.slide.macroenabled.12"
    , "application/vnd.ms-powerpoint.slideshow.macroenabled.12"
    , "application/vnd.ms-powerpoint.template.macroenabled.12"
    , "application/vnd.ms-project"
    , "application/vnd.ms-word.document.macroenabled.12"
    , "application/vnd.ms-word.template.macroenabled.12"
    , "application/vnd.ms-works"
    , "application/vnd.ms-wpl"
    , "application/vnd.ms-xpsdocument"
    , "application/vnd.mseq"
    , "application/vnd.musician"
    , "application/vnd.muvee.style"
    , "application/vnd.neurolanguage.nlu"
    , "application/vnd.noblenet-directory"
    , "application/vnd.noblenet-sealer"
    , "application/vnd.noblenet-web"
    , "application/vnd.nokia.n-gage.data"
    , "application/vnd.nokia.n-gage.symbian.install\t."
    , "application/vnd.nokia.radio-preset"
    , "application/vnd.nokia.radio-presets"
    , "application/vnd.novadigm.edm"
    , "application/vnd.novadigm.edx"
    , "application/vnd.novadigm.ext"
    , "application/vnd.oasis.opendocument.chart"
    , "application/vnd.oasis.opendocument.chart-template"
    , "application/vnd.oasis.opendocument.database"
    , "application/vnd.oasis.opendocument.formula"
    , "application/vnd.oasis.opendocument.formula-template"
    , "application/vnd.oasis.opendocument.graphics"
    , "application/vnd.oasis.opendocument.graphics-template"
    , "application/vnd.oasis.opendocument.image"
    , "application/vnd.oasis.opendocument.image-template"
    , "application/vnd.oasis.opendocument.presentation"
    , "application/vnd.oasis.opendocument.presentation-template"
    , "application/vnd.oasis.opendocument.spreadsheet"
    , "application/vnd.oasis.opendocument.spreadsheet-template"
    , "application/vnd.oasis.opendocument.text"
    , "application/vnd.oasis.opendocument.text-master"
    , "application/vnd.oasis.opendocument.text-template"
    , "application/vnd.oasis.opendocument.text-web"
    , "application/vnd.olpc-sugar"
    , "application/vnd.oma.dd2+xml"
    , "application/vnd.openofficeorg.extension"
    , "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    , "application/vnd.openxmlformats-officedocument.presentationml.slide"
    , "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
    , "application/vnd.openxmlformats-officedocument.presentationml.template"
    , "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    , "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
    , "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    , "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
    , "application/vnd.osgi.dp"
    , "application/vnd.palm"
    , "application/vnd.pg.format"
    , "application/vnd.pg.osasli"
    , "application/vnd.picsel"
    , "application/vnd.pocketlearn"
    , "application/vnd.powerbuilder6"
    , "application/vnd.previewsystems.box"
    , "application/vnd.proteus.magazine"
    , "application/vnd.publishare-delta-tree"
    , "application/vnd.pvi.ptid1"
    , "application/vnd.quark.quarkxpress"
    , "application/vnd.rar"
    , "application/vnd.recordare.musicxml"
    , "application/vnd.recordare.musicxml+xml"
    , "application/vnd.rim.cod"
    , "application/vnd.rn-realmedia"
    , "application/vnd.route66.link66+xml"
    , "application/vnd.seemail"
    , "application/vnd.sema"
    , "application/vnd.semd"
    , "application/vnd.semf"
    , "application/vnd.shana.informed.formdata"
    , "application/vnd.shana.informed.formtemplate"
    , "application/vnd.shana.informed.interchange"
    , "application/vnd.shana.informed.package"
    , "application/vnd.simtech-mindmapper"
    , "application/vnd.smaf"
    , "application/vnd.smart.teacher"
    , "application/vnd.solent.sdkm+xml"
    , "application/vnd.spotfire.dxp"
    , "application/vnd.spotfire.sfs"
    , "application/vnd.sqlite3"
    , "application/vnd.stardivision.calc"
    , "application/vnd.stardivision.draw"
    , "application/vnd.stardivision.impress"
    , "application/vnd.stardivision.math"
    , "application/vnd.stardivision.writer"
    , "application/vnd.stardivision.writer-global"
    , "application/vnd.sun.xml.calc"
    , "application/vnd.sun.xml.calc.template"
    , "application/vnd.sun.xml.draw"
    , "application/vnd.sun.xml.draw.template"
    , "application/vnd.sun.xml.impress"
    , "application/vnd.sun.xml.impress.template"
    , "application/vnd.sun.xml.math"
    , "application/vnd.sun.xml.writer"
    , "application/vnd.sun.xml.writer.global"
    , "application/vnd.sun.xml.writer.template"
    , "application/vnd.sus-calendar"
    , "application/vnd.svd"
    , "application/vnd.symbian.install"
    , "application/vnd.syncml+xml"
    , "application/vnd.syncml.dm+wbxml"
    , "application/vnd.syncml.dm+xml"
    , "application/vnd.tao.intent-module-archive"
    , "application/vnd.tmobile-livetv"
    , "application/vnd.trid.tpt"
    , "application/vnd.triscape.mxs"
    , "application/vnd.trueapp"
    , "application/vnd.ufdl"
    , "application/vnd.uiq.theme"
    , "application/vnd.umajin"
    , "application/vnd.unity"
    , "application/vnd.uoml+xml"
    , "application/vnd.vcx"
    , "application/vnd.visio"
    , "application/vnd.visionary"
    , "application/vnd.vsf"
    , "application/vnd.wap.sic"
    , "application/vnd.wap.slc"
    , "application/vnd.wap.wbxml"
    , "application/vnd.wap.wmlc"
    , "application/vnd.wap.wmlscriptc"
    , "application/vnd.webturbo"
    , "application/vnd.wordperfect"
    , "application/vnd.wqd"
    , "application/vnd.wt.stf"
    , "application/vnd.xara"
    , "application/vnd.xfdl"
    , "application/vnd.yamaha.hv-dic"
    , "application/vnd.yamaha.hv-script"
    , "application/vnd.yamaha.hv-voice"
    , "application/vnd.yamaha.openscoreformat"
    , "application/vnd.yamaha.openscoreformat.osfpvg+xml"
    , "application/vnd.yamaha.smaf-audio"
    , "application/vnd.yamaha.smaf-phrase"
    , "application/vnd.yellowriver-custom-menu"
    , "application/vnd.zul"
    , "application/vnd.zzazz.deck+xml"
    , "application/voicexml+xml"
    , "application/wasm"
    , "application/winhlp"
    , "application/wsdl+xml"
    , "application/wspolicy+xml"
    , "application/x-7z-compressed"
    , "application/x-abiword"
    , "application/x-ace-compressed"
    , "application/x-authorware-bin"
    , "application/x-authorware-map"
    , "application/x-authorware-seg"
    , "application/x-bcpio"
    , "application/x-bittorrent"
    , "application/x-bzip"
    , "application/x-bzip2"
    , "application/x-cdlink"
    , "application/x-chat"
    , "application/x-chess-pgn"
    , "application/x-cpio"
    , "application/x-csh"
    , "application/x-debian-package"
    , "application/x-director"
    , "application/x-doom"
    , "application/x-dtbncx+xml"
    , "application/x-dtbook+xml"
    , "application/x-dtbresource+xml"
    , "application/x-dvi"
    , "application/x-font-bdf"
    , "application/x-font-ghostscript"
    , "application/x-font-linux-psf"
    , "application/x-font-otf"
    , "application/x-font-pcf"
    , "application/x-font-snf"
    , "application/x-font-ttf"
    , "application/x-font-type1"
    , "application/x-futuresplash"
    , "application/x-gnumeric"
    , "application/x-gtar"
    , "application/x-gzip"
    , "application/x-hdf"
    , "application/x-iso9660-image"
    , "application/x-java-jnlp-file"
    , "application/x-killustrator"
    , "application/x-krita"
    , "application/x-latex"
    , "application/x-mobipocket-ebook"
    , "application/x-ms-application"
    , "application/x-ms-wmd"
    , "application/x-ms-wmz"
    , "application/x-ms-xbap"
    , "application/x-msaccess"
    , "application/x-msbinder"
    , "application/x-mscardfile"
    , "application/x-msclip"
    , "application/x-msdownload"
    , "application/x-msmediaview"
    , "application/x-msmetafile"
    , "application/x-msmoney"
    , "application/x-mspublisher"
    , "application/x-msschedule"
    , "application/x-msterminal"
    , "application/x-mswrite"
    , "application/x-netcdf"
    , "application/x-perl"
    , "application/x-pkcs12"
    , "application/x-pkcs7-certificates"
    , "application/x-pkcs7-certreqresp"
    , "application/x-rar-compressed"
    , "application/x-redhat-package-manager"
    , "application/x-rpm"
    , "application/x-sh"
    , "application/x-shar"
    , "application/x-shellscript"
    , "application/x-shockwave-flash"
    , "application/x-silverlight-app"
    , "application/x-stuffit"
    , "application/x-stuffitx"
    , "application/x-sv4cpio"
    , "application/x-sv4crc"
    , "application/x-tar"
    , "application/x-tcl"
    , "application/x-tex"
    , "application/x-tex-tfm"
    , "application/x-texinfo"
    , "application/"
    , "application/x-ustar"
    , "application/x-wais-source"
    , "application/x-x509-ca-cert"
    , "application/x-xfig"
    , "application/x-xpinstall"
    , "application/x-zip-compressed"
    , "application/xenc+xml"
    , "application/xhtml+xml"
    , "application/xml"
    , "application/xml-dtd"
    , "application/xop+xml"
    , "application/xslt+xml"
    , "application/xspf+xml"
    , "application/xv+xml"
    , "application/yaml"
    , "application/zip"
    , "application/zip-compressed"
    , "chemical/x-cdx"
    , "chemical/x-cif"
    , "chemical/x-cmdf"
    , "chemical/x-cml"
    , "chemical/x-csml"
    , "chemical/x-xyz"
    , "font/otf"
    , "font/woff"
    , "font/woff2"
    , "gcode"
    , "image/avif"
    , "image/avif-sequence"
    , "image/bmp"
    , "image/cgm"
    , "image/g3fax"
    , "image/heic"
    , "image/ief"
    , "image/pjpeg"
    , "image/prs.btif"
    , "image/svg+xml"
    , "image/tiff"
    , "image/vnd.adobe.photoshop"
    , "image/vnd.djvu"
    , "image/vnd.dwg"
    , "image/vnd.dxf"
    , "image/vnd.fastbidsheet"
    , "image/vnd.fpx"
    , "image/vnd.fst"
    , "image/vnd.fujixerox.edmics-mmr"
    , "image/vnd.fujixerox.edmics-rlc"
    , "image/vnd.ms-modi"
    , "image/vnd.net-fpx"
    , "image/vnd.wap.wbmp"
    , "image/vnd.xiff"
    , "image/x-adobe-dng"
    , "image/x-canon-cr2"
    , "image/x-canon-crw"
    , "image/x-cmu-raster"
    , "image/x-cmx"
    , "image/x-epson-erf"
    , "image/x-freehand"
    , "image/x-fuji-raf"
    , "image/x-icns"
    , "image/x-icon"
    , "image/x-kodak-dcr"
    , "image/x-kodak-k25"
    , "image/x-kodak-kdc"
    , "image/x-minolta-mrw"
    , "image/x-nikon-nef"
    , "image/x-olympus-orf"
    , "image/x-panasonic-raw"
    , "image/x-pcx"
    , "image/x-pentax-pef"
    , "image/x-pict"
    , "image/x-portable-anymap"
    , "image/x-portable-bitmap"
    , "image/x-portable-graymap"
    , "image/x-portable-pixmap"
    , "image/x-rgb"
    , "image/x-sigma-x3f"
    , "image/x-sony-arw"
    , "image/x-sony-sr2"
    , "image/x-sony-srf"
    , "image/x-xbitmap"
    , "image/x-xpixmap"
    , "image/x-xwindowdump"
    , "message/rfc822"
    , "model/iges"
    , "model/mesh"
    , "model/vnd.dwf"
    , "model/vnd.gdl"
    , "model/vnd.gtw"
    , "model/vnd.mts"
    , "model/vnd.vtu"
    , "model/vrml"
    , "test/mimetype"
    , "test/mimetyp"
    , "x-conference/x-cooltalk"
    , "image/apng"
    ]
        |> List.indexedMap (\index contentType2 -> ( ContentType index, contentType2 ))
        |> OneToOne.fromList

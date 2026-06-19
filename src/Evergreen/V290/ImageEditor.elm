module Evergreen.V290.ImageEditor exposing (..)

import Effect.Browser.Dom
import Effect.File
import Effect.Http
import Evergreen.V290.FileStatus
import Evergreen.V290.Id
import Evergreen.V290.Ports


type DragPart
    = TopLeft
    | TopRight
    | BottomLeft
    | BottomRight
    | Center


type alias DragState =
    { startX : Float
    , startY : Float
    , dragPart : DragPart
    , currentX : Float
    , currentY : Float
    }


type UploadStatus
    = NotUploaded
    | Cropping
    | Uploading Evergreen.V290.FileStatus.FileHash
    | UploadingError


type alias Model =
    { x : Float
    , y : Float
    , size : Float
    , imageUrl : Maybe String
    , dragState : Maybe DragState
    , imageSize : Maybe ( Int, Int )
    , status : UploadStatus
    }


type ToFrontend
    = ChangeUserAvatarResponse
    | ChangeGuildIconResponse (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)


type Msg
    = PressedProfileImage
    | SelectedImage Effect.File.File
    | GotImageUrl String
    | MouseDownImageEditor Float Float
    | MouseUpImageEditor
    | MovedImageEditor Float Float
    | TouchEndImageEditor
    | PressedConfirmImage
    | GotImageSize (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | CroppedImage (Result String Evergreen.V290.Ports.CropImageDataResponse)
    | PressedCancel
    | UploadedImage (Result Effect.Http.Error Evergreen.V290.FileStatus.UploadResponse)


type ToBackend
    = ChangeUserAvatarRequest Evergreen.V290.FileStatus.FileHash
    | ChangeGuildIconRequest (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.FileStatus.FileHash

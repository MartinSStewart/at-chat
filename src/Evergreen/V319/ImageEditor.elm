module Evergreen.V319.ImageEditor exposing (..)

import Effect.Browser.Dom
import Effect.File
import Effect.Http
import Evergreen.V319.FileStatus
import Evergreen.V319.Id
import Evergreen.V319.Ports


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
    | CroppedImage (Result String Evergreen.V319.Ports.CropImageDataResponse)
    | PressedCancel
    | UploadedImage (Result Effect.Http.Error Evergreen.V319.FileStatus.UploadResponse)


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
    | Uploading Evergreen.V319.FileStatus.FileHash
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
    | ChangeGuildIconResponse (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)


type ToBackend
    = ChangeUserAvatarRequest Evergreen.V319.FileStatus.FileHash
    | ChangeGuildIconRequest (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.FileStatus.FileHash

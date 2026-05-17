module Evergreen.V232.ImageEditor exposing (..)

import Effect.Browser.Dom
import Effect.File
import Effect.Http
import Evergreen.V232.FileStatus
import Evergreen.V232.Id
import Evergreen.V232.Ports


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
    | Uploading Evergreen.V232.FileStatus.FileHash
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
    | ChangeGuildIconResponse (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId)


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
    | CroppedImage (Result String Evergreen.V232.Ports.CropImageDataResponse)
    | PressedCancel
    | UploadedImage (Result Effect.Http.Error Evergreen.V232.FileStatus.UploadResponse)


type ToBackend
    = ChangeUserAvatarRequest Evergreen.V232.FileStatus.FileHash
    | ChangeGuildIconRequest (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) Evergreen.V232.FileStatus.FileHash

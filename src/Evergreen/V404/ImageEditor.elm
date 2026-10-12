module Evergreen.V404.ImageEditor exposing (..)

import Effect.Browser.Dom
import Effect.File
import Effect.Http
import Evergreen.V404.FileStatus
import Evergreen.V404.Id
import Evergreen.V404.Ports


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
    | CroppedImage (Result String Evergreen.V404.Ports.CropImageDataResponse)
    | PressedCancel
    | PressedRemoveImage
    | UploadedImage (Result Effect.Http.Error Evergreen.V404.FileStatus.UploadResponse)


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
    | Uploading Evergreen.V404.FileStatus.FileHash
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
    | ChangeGuildIconResponse (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId)


type ToBackend
    = ChangeUserAvatarRequest (Maybe Evergreen.V404.FileStatus.FileHash)
    | ChangeGuildIconRequest (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) (Maybe Evergreen.V404.FileStatus.FileHash)

module Evergreen.V357.ImageEditor exposing (..)

import Effect.Browser.Dom
import Effect.File
import Effect.Http
import Evergreen.V357.FileStatus
import Evergreen.V357.Id
import Evergreen.V357.Ports


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
    | CroppedImage (Result String Evergreen.V357.Ports.CropImageDataResponse)
    | PressedCancel
    | PressedRemoveImage
    | UploadedImage (Result Effect.Http.Error Evergreen.V357.FileStatus.UploadResponse)


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
    | Uploading Evergreen.V357.FileStatus.FileHash
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
    | ChangeGuildIconResponse (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)


type ToBackend
    = ChangeUserAvatarRequest (Maybe Evergreen.V357.FileStatus.FileHash)
    | ChangeGuildIconRequest (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Maybe Evergreen.V357.FileStatus.FileHash)

module Evergreen.V365.ImageEditor exposing (..)

import Effect.Browser.Dom
import Effect.File
import Effect.Http
import Evergreen.V365.FileStatus
import Evergreen.V365.Id
import Evergreen.V365.Ports


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
    | CroppedImage (Result String Evergreen.V365.Ports.CropImageDataResponse)
    | PressedCancel
    | PressedRemoveImage
    | UploadedImage (Result Effect.Http.Error Evergreen.V365.FileStatus.UploadResponse)


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
    | Uploading Evergreen.V365.FileStatus.FileHash
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
    | ChangeGuildIconResponse (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)


type ToBackend
    = ChangeUserAvatarRequest (Maybe Evergreen.V365.FileStatus.FileHash)
    | ChangeGuildIconRequest (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Maybe Evergreen.V365.FileStatus.FileHash)

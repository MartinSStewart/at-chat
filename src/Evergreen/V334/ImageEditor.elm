module Evergreen.V334.ImageEditor exposing (..)

import Effect.Browser.Dom
import Effect.File
import Effect.Http
import Evergreen.V334.FileStatus
import Evergreen.V334.Id
import Evergreen.V334.Ports


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
    | CroppedImage (Result String Evergreen.V334.Ports.CropImageDataResponse)
    | PressedCancel
    | PressedRemoveImage
    | UploadedImage (Result Effect.Http.Error Evergreen.V334.FileStatus.UploadResponse)


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
    | Uploading Evergreen.V334.FileStatus.FileHash
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
    | ChangeGuildIconResponse (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId)


type ToBackend
    = ChangeUserAvatarRequest (Maybe Evergreen.V334.FileStatus.FileHash)
    | ChangeGuildIconRequest (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) (Maybe Evergreen.V334.FileStatus.FileHash)

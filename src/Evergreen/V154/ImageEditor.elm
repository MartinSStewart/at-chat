module Evergreen.V154.ImageEditor exposing (..)

import Effect.Browser.Dom
import Effect.File
import Effect.Http
import Evergreen.V154.FileStatus
import Evergreen.V154.Ports


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
    | Uploading Evergreen.V154.FileStatus.FileHash
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
    | CroppedImage (Result String Evergreen.V154.Ports.CropImageDataResponse)
    | PressedCancel
    | UploadedImage (Result Effect.Http.Error Evergreen.V154.FileStatus.UploadResponse)


type ToBackend
    = ChangeUserAvatarRequest Evergreen.V154.FileStatus.FileHash


type ToFrontend
    = ChangeUserAvatarResponse

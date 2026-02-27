module Evergreen.V122.Ports exposing (..)


type NotificationPermission
    = NotAsked
    | Denied
    | Granted
    | Unsupported


type PwaStatus
    = InstalledPwa
    | BrowserView


type alias CropImageDataResponse =
    { requestId : Int
    , croppedImageUrl : String
    }

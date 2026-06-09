module Evergreen.V283.Ports exposing (..)

import Time
import Url


type alias SubscribeKeys =
    { auth : String
    , p256dh : String
    }


type alias SubscribeData =
    { endpoint : Url.Url
    , expirationTime : Maybe Time.Posix
    , keys : SubscribeKeys
    }


type NotificationPermission
    = NotAsked
    | Denied
    | Granted
    | Unsupported


type PwaStatus
    = InstalledPwa
    | BrowserView


type RegisterPushSubscription
    = GotSubscribeData SubscribeData
    | SubscribeJsException String


type alias CropImageDataResponse =
    { requestId : Int
    , croppedImageUrl : String
    }

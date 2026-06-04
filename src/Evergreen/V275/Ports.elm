module Evergreen.V275.Ports exposing (..)

import Url


type alias SubscribeKeys =
    { auth : String
    , p256dh : String
    }


type alias SubscribeData =
    { endpoint : Url.Url
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

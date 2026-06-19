module Evergreen.V290.Ports exposing (..)

import Evergreen.V290.UserAgent
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


type PwaStatus
    = InstalledPwa
    | BrowserView


type NotificationPermission
    = NotAsked
    | Denied
    | Granted
    | Unsupported


type alias StartupData =
    { timeOrigin : Time.Posix
    , userAgent : Evergreen.V290.UserAgent.UserAgent
    , scrollbarWidth : Int
    , pwaStatus : PwaStatus
    , notificationPermission : NotificationPermission
    }


type RegisterPushSubscription
    = GotSubscribeData SubscribeData
    | SubscribeJsException String


type alias CropImageDataResponse =
    { requestId : Int
    , croppedImageUrl : String
    }

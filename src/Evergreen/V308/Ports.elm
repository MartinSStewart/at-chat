module Evergreen.V308.Ports exposing (..)

import Evergreen.V308.UserAgent
import Time
import Url


type NotificationPermission
    = NotAsked
    | Denied
    | Granted
    | Unsupported


type alias CropImageDataResponse =
    { requestId : Int
    , croppedImageUrl : String
    }


type alias SubscribeKeys =
    { auth : String
    , p256dh : String
    }


type alias SubscribeData =
    { endpoint : Url.Url
    , expirationTime : Maybe Time.Posix
    , keys : SubscribeKeys
    }


type RegisterPushSubscription
    = GotSubscribeData SubscribeData
    | SubscribeJsException String


type PwaStatus
    = InstalledPwa
    | BrowserView


type alias StartupData =
    { timeOrigin : Time.Posix
    , userAgent : Evergreen.V308.UserAgent.UserAgent
    , scrollbarWidth : Int
    , pwaStatus : PwaStatus
    , notificationPermission : NotificationPermission
    , safeAreaInsetTop : Int
    }

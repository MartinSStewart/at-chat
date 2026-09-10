module Evergreen.V376.Ports exposing (..)

import Evergreen.V376.Id
import Evergreen.V376.UserAgent
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
    , loadStartupDataTime : Time.Posix
    , userAgent : Evergreen.V376.UserAgent.UserAgent
    , scrollbarWidth : Int
    , pwaStatus : PwaStatus
    , notificationPermission : NotificationPermission
    , safeAreaInsetTop : Int
    , devicePixelRatio : Float
    , timezone : Time.Zone
    , randomSeed : List Int
    , e2eeKeys : List (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    }

module Evergreen.V39.Ports exposing (..)

import Url


type NotificationPermission
    = NotAsked
    | Denied
    | Granted
    | Unsupported


type PwaStatus
    = InstalledPwa
    | BrowserView


type alias PushSubscription =
    { endpoint : Url.Url
    , auth : String
    , p256dh : String
    }

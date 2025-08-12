module Evergreen.V26.Ports exposing (..)


type NotificationPermission
    = NotAsked
    | Denied
    | Granted
    | Unsupported


type PwaStatus
    = InstalledPwa
    | BrowserView

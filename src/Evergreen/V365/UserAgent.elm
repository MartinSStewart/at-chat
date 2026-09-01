module Evergreen.V365.UserAgent exposing (..)


type Browser
    = Chrome
    | Firefox
    | Safari
    | Edge
    | Opera
    | UnknownBrowser


type Device
    = IPhone
    | IPad
    | AndroidPhone
    | AndroidTablet
    | Windows
    | MacOS
    | ChromeOS
    | Linux
    | Mobile
    | Tablet
    | Desktop


type alias UserAgent =
    { browser : Browser
    , device : Device
    }

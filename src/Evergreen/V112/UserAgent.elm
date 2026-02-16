module Evergreen.V112.UserAgent exposing (..)


type Browser
    = Chrome
    | Firefox
    | Safari
    | Edge
    | Opera
    | UnknownBrowser


type Device
    = Desktop
    | Mobile
    | Tablet


type alias UserAgent =
    { browser : Browser
    , device : Device
    }

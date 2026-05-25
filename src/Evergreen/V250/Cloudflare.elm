module Evergreen.V250.Cloudflare exposing (..)


type alias TurnConfig =
    { urls : List String
    , username : Maybe String
    , credential : Maybe String
    }

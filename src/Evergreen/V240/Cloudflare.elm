module Evergreen.V240.Cloudflare exposing (..)


type alias TurnConfig =
    { urls : List String
    , username : Maybe String
    , credential : Maybe String
    }

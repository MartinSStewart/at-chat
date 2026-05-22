module Evergreen.V247.Cloudflare exposing (..)


type alias TurnConfig =
    { urls : List String
    , username : Maybe String
    , credential : Maybe String
    }

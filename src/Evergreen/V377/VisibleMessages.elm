module Evergreen.V377.VisibleMessages exposing (..)

import Evergreen.V377.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V377.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }

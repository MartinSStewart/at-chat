module Evergreen.V387.VisibleMessages exposing (..)

import Evergreen.V387.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V387.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }

module Evergreen.V367.VisibleMessages exposing (..)

import Evergreen.V367.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V367.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }

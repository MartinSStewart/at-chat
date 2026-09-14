module Evergreen.V382.VisibleMessages exposing (..)

import Evergreen.V382.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V382.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }

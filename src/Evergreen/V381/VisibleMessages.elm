module Evergreen.V381.VisibleMessages exposing (..)

import Evergreen.V381.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V381.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }

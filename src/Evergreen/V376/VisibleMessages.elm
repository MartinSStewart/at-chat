module Evergreen.V376.VisibleMessages exposing (..)

import Evergreen.V376.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V376.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }

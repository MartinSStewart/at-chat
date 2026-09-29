module Evergreen.V394.VisibleMessages exposing (..)

import Evergreen.V394.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V394.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }

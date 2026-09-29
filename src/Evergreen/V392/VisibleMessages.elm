module Evergreen.V392.VisibleMessages exposing (..)

import Evergreen.V392.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V392.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }

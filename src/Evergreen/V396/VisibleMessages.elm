module Evergreen.V396.VisibleMessages exposing (..)

import Evergreen.V396.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V396.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }

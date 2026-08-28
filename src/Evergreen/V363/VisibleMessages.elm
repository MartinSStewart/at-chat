module Evergreen.V363.VisibleMessages exposing (..)

import Evergreen.V363.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V363.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }

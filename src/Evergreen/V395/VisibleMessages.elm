module Evergreen.V395.VisibleMessages exposing (..)

import Evergreen.V395.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V395.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }

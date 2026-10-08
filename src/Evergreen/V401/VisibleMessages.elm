module Evergreen.V401.VisibleMessages exposing (..)

import Evergreen.V401.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V401.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }

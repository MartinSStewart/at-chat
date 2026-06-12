module Evergreen.V285.VisibleMessages exposing (..)

import Evergreen.V285.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V285.Id.Id messageId
    , count : Int
    }

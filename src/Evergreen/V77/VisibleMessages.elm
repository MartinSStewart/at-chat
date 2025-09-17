module Evergreen.V77.VisibleMessages exposing (..)

import Evergreen.V77.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V77.Id.Id messageId
    , count : Int
    }

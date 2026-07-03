module Evergreen.V301.VisibleMessages exposing (..)

import Evergreen.V301.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V301.Id.Id messageId
    , count : Int
    }

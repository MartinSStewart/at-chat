module Evergreen.V304.VisibleMessages exposing (..)

import Evergreen.V304.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V304.Id.Id messageId
    , count : Int
    }

module Evergreen.V135.VisibleMessages exposing (..)

import Evergreen.V135.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V135.Id.Id messageId
    , count : Int
    }

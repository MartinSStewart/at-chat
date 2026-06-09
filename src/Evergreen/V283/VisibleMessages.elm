module Evergreen.V283.VisibleMessages exposing (..)

import Evergreen.V283.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V283.Id.Id messageId
    , count : Int
    }

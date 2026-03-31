module Evergreen.V182.VisibleMessages exposing (..)

import Evergreen.V182.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V182.Id.Id messageId
    , count : Int
    }

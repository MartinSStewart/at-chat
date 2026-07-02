module Evergreen.V299.VisibleMessages exposing (..)

import Evergreen.V299.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V299.Id.Id messageId
    , count : Int
    }

module Evergreen.V248.VisibleMessages exposing (..)

import Evergreen.V248.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V248.Id.Id messageId
    , count : Int
    }

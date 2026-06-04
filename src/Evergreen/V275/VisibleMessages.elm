module Evergreen.V275.VisibleMessages exposing (..)

import Evergreen.V275.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V275.Id.Id messageId
    , count : Int
    }

module Evergreen.V59.VisibleMessages exposing (..)

import Evergreen.V59.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V59.Id.Id messageId
    , count : Int
    }

module Evergreen.V339.VisibleMessages exposing (..)

import Evergreen.V339.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V339.Id.Id messageId
    , count : Int
    }

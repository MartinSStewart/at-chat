module Evergreen.V157.VisibleMessages exposing (..)

import Evergreen.V157.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V157.Id.Id messageId
    , count : Int
    }
